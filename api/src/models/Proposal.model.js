const mongoose = require('mongoose');

const proposalVoteSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  isUpvote: {
    type: Boolean,
    required: true
  },
  votedAt: {
    type: Date,
    default: Date.now
  }
});

const proposalCommentSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  content: {
    type: String,
    required: true,
    trim: true,
    maxlength: [500, 'El comentario no puede tener más de 500 caracteres']
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const proposalSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'El título es requerido'],
    trim: true,
    maxlength: [100, 'El título no puede tener más de 100 caracteres']
  },
  description: {
    type: String,
    required: [true, 'La descripción es requerida'],
    maxlength: [1000, 'La descripción no puede tener más de 1000 caracteres']
  },
  proposedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  status: {
    type: String,
    enum: ['pendiente', 'enRevision', 'aprobada', 'rechazada', 'enProgreso', 'completada'],
    default: 'pendiente'
  },
  priority: {
    type: String,
    enum: ['baja', 'media', 'alta', 'urgente'],
    default: 'media'
  },
  attachments: [{
    type: String
  }],
  votes: [proposalVoteSchema],
  comments: [proposalCommentSchema],
  estimatedCost: {
    type: Number,
    min: [0, 'El costo estimado debe ser mayor a 0'],
    default: null
  },
  adminResponse: {
    type: String,
    default: null
  },
  adminResponseDate: {
    type: Date,
    default: null
  },
  adminResponseBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  }
}, {
  timestamps: true
});

// Indexes
proposalSchema.index({ proposedBy: 1 });
proposalSchema.index({ status: 1, priority: -1 });
proposalSchema.index({ createdAt: -1 });

// Virtual for upvotes count
proposalSchema.virtual('upvotes').get(function() {
  return this.votes.filter(vote => vote.isUpvote).length;
});

// Virtual for downvotes count
proposalSchema.virtual('downvotes').get(function() {
  return this.votes.filter(vote => !vote.isUpvote).length;
});

// Virtual for score
proposalSchema.virtual('score').get(function() {
  return this.upvotes - this.downvotes;
});

// Method to check if user has voted
proposalSchema.methods.hasUserVoted = function(userId) {
  return this.votes.some(vote => vote.user.toString() === userId.toString());
};

// Method to get user's vote
proposalSchema.methods.getUserVote = function(userId) {
  return this.votes.find(vote => vote.user.toString() === userId.toString());
};

// Method to vote
proposalSchema.methods.vote = function(userId, isUpvote) {
  const existingVoteIndex = this.votes.findIndex(
    vote => vote.user.toString() === userId.toString()
  );
  
  if (existingVoteIndex !== -1) {
    // Update existing vote
    this.votes[existingVoteIndex].isUpvote = isUpvote;
    this.votes[existingVoteIndex].votedAt = new Date();
  } else {
    // Add new vote
    this.votes.push({
      user: userId,
      isUpvote: isUpvote
    });
  }
  
  return this.save();
};

// Method to remove vote
proposalSchema.methods.removeVote = function(userId) {
  this.votes = this.votes.filter(
    vote => vote.user.toString() !== userId.toString()
  );
  return this.save();
};

// Method to add comment
proposalSchema.methods.addComment = function(userId, content) {
  this.comments.push({ user: userId, content });
  return this.save();
};

// Method to remove comment
proposalSchema.methods.removeComment = function(commentId, userId) {
  const comment = this.comments.id(commentId);
  if (!comment) {
    throw new Error('Comentario no encontrado');
  }
  
  if (comment.user.toString() !== userId.toString()) {
    throw new Error('No tienes permiso para eliminar este comentario');
  }
  
  comment.remove();
  return this.save();
};

// Method to update status
proposalSchema.methods.updateStatus = function(status, adminId, response = null) {
  this.status = status;
  if (response) {
    this.adminResponse = response;
    this.adminResponseDate = new Date();
    this.adminResponseBy = adminId;
  }
  return this.save();
};

module.exports = mongoose.model('Proposal', proposalSchema);
