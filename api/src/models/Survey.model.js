const mongoose = require('mongoose');

const surveyOptionSchema = new mongoose.Schema({
  text: {
    type: String,
    required: true,
    trim: true
  },
  emoji: {
    type: String,
    default: null
  }
});

const surveyVoteSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  selectedOptions: [{
    type: mongoose.Schema.Types.ObjectId
  }],
  votedAt: {
    type: Date,
    default: Date.now
  }
});

const surveySchema = new mongoose.Schema({
  question: {
    type: String,
    required: [true, 'La pregunta es requerida'],
    trim: true,
    maxlength: [200, 'La pregunta no puede tener más de 200 caracteres']
  },
  options: {
    type: [surveyOptionSchema],
    validate: {
      validator: function(v) {
        return v && v.length >= 2;
      },
      message: 'Una encuesta debe tener al menos 2 opciones'
    }
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  expiresAt: {
    type: Date,
    default: null
  },
  allowMultipleAnswers: {
    type: Boolean,
    default: false
  },
  isAnonymous: {
    type: Boolean,
    default: false
  },
  votes: [surveyVoteSchema],
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Indexes
surveySchema.index({ createdBy: 1 });
surveySchema.index({ isActive: 1, expiresAt: 1 });

// Virtual for total votes
surveySchema.virtual('totalVotes').get(function() {
  return this.votes.length;
});

// Virtual for vote counts by option
surveySchema.virtual('voteCounts').get(function() {
  const counts = {};
  this.options.forEach(option => {
    counts[option._id] = 0;
  });
  
  this.votes.forEach(vote => {
    vote.selectedOptions.forEach(optionId => {
      if (counts[optionId] !== undefined) {
        counts[optionId]++;
      }
    });
  });
  
  return counts;
});

// Method to check if user has voted
surveySchema.methods.hasUserVoted = function(userId) {
  return this.votes.some(vote => vote.user.toString() === userId.toString());
};

// Method to get user's vote
surveySchema.methods.getUserVote = function(userId) {
  return this.votes.find(vote => vote.user.toString() === userId.toString());
};

// Pre-save hook to check expiration
surveySchema.pre('save', function(next) {
  if (this.expiresAt && this.expiresAt < new Date()) {
    this.isActive = false;
  }
  next();
});

module.exports = mongoose.model('Survey', surveySchema);
