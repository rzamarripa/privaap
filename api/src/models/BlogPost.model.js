const mongoose = require('mongoose');

const commentSchema = new mongoose.Schema({
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

const blogPostSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'El título es requerido'],
    trim: true,
    maxlength: [100, 'El título no puede tener más de 100 caracteres']
  },
  content: {
    type: String,
    required: [true, 'El contenido es requerido'],
    maxlength: [5000, 'El contenido no puede tener más de 5000 caracteres']
  },
  author: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  category: {
    type: String,
    required: [true, 'La categoría es requerida'],
    enum: ['anuncio', 'mantenimiento', 'evento', 'mejora', 'seguridad', 'general']
  },
  images: [{
    type: String
  }],
  tags: [{
    type: String,
    lowercase: true,
    trim: true
  }],
  likes: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  comments: [commentSchema],
  isPinned: {
    type: Boolean,
    default: false
  },
  isPublished: {
    type: Boolean,
    default: true
  },
  views: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Indexes
blogPostSchema.index({ author: 1 });
blogPostSchema.index({ category: 1 });
blogPostSchema.index({ tags: 1 });
blogPostSchema.index({ isPinned: -1, createdAt: -1 });

// Virtual for likes count
blogPostSchema.virtual('likesCount').get(function() {
  return this.likes.length;
});

// Virtual for comments count
blogPostSchema.virtual('commentsCount').get(function() {
  return this.comments.length;
});

// Method to check if user has liked
blogPostSchema.methods.hasUserLiked = function(userId) {
  return this.likes.some(like => like.toString() === userId.toString());
};

// Method to toggle like
blogPostSchema.methods.toggleLike = function(userId) {
  const index = this.likes.findIndex(like => like.toString() === userId.toString());
  if (index === -1) {
    this.likes.push(userId);
  } else {
    this.likes.splice(index, 1);
  }
  return this.save();
};

// Method to add comment
blogPostSchema.methods.addComment = function(userId, content) {
  this.comments.push({ user: userId, content });
  return this.save();
};

// Method to remove comment
blogPostSchema.methods.removeComment = function(commentId, userId) {
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

// Method to increment views
blogPostSchema.methods.incrementViews = function() {
  this.views++;
  return this.save();
};

module.exports = mongoose.model('BlogPost', blogPostSchema);
