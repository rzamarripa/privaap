const { validationResult } = require('express-validator');
const BlogPost = require('../models/BlogPost.model');

// @desc    Get all blog posts
// @route   GET /api/blog
// @access  Private
exports.getAllPosts = async (req, res, next) => {
  try {
    const posts = await BlogPost.find({ isPublished: true })
      .populate('author', 'name email')
      .sort('-createdAt');
    
    res.json({
      success: true,
      count: posts.length,
      data: posts
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get blog post by ID
// @route   GET /api/blog/:id
// @access  Private
exports.getPostById = async (req, res, next) => {
  try {
    const post = await BlogPost.findById(req.params.id)
      .populate('author', 'name email')
      .populate('comments.user', 'name');
    
    if (!post) {
      return res.status(404).json({ error: 'Post no encontrado' });
    }
    
    res.json({
      success: true,
      data: post
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get posts by author
// @route   GET /api/blog/author/:authorId
// @access  Private
exports.getPostsByAuthor = async (req, res, next) => {
  try {
    const posts = await BlogPost.find({ 
      author: req.params.authorId,
      isPublished: true 
    })
      .populate('author', 'name email')
      .sort('-createdAt');
    
    res.json({
      success: true,
      count: posts.length,
      data: posts
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get posts by tag
// @route   GET /api/blog/tag/:tag
// @access  Private
exports.getPostsByTag = async (req, res, next) => {
  try {
    const posts = await BlogPost.find({ 
      tags: req.params.tag,
      isPublished: true 
    })
      .populate('author', 'name email')
      .sort('-createdAt');
    
    res.json({
      success: true,
      count: posts.length,
      data: posts
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create new blog post
// @route   POST /api/blog
// @access  Private/Admin
exports.createPost = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const postData = {
      ...req.body,
      author: req.user._id
    };
    
    const post = await BlogPost.create(postData);
    
    res.status(201).json({
      success: true,
      data: post
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update blog post
// @route   PUT /api/blog/:id
// @access  Private/Admin
exports.updatePost = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const post = await BlogPost.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    
    if (!post) {
      return res.status(404).json({ error: 'Post no encontrado' });
    }
    
    res.json({
      success: true,
      data: post
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Toggle publish status
// @route   PATCH /api/blog/:id/publish
// @access  Private/Admin
exports.togglePublishStatus = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { isPublished } = req.body;
    
    const post = await BlogPost.findByIdAndUpdate(
      req.params.id,
      { isPublished },
      { new: true, runValidators: true }
    );
    
    if (!post) {
      return res.status(404).json({ error: 'Post no encontrado' });
    }
    
    res.json({
      success: true,
      data: post
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add comment to post
// @route   POST /api/blog/:id/comments
// @access  Private
exports.addComment = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const post = await BlogPost.findById(req.params.id);
    
    if (!post) {
      return res.status(404).json({ error: 'Post no encontrado' });
    }
    
    post.comments.push({
      user: req.user._id,
      content: req.body.content
    });
    
    await post.save();
    
    res.json({
      success: true,
      data: post.comments
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete comment
// @route   DELETE /api/blog/:id/comments/:commentId
// @access  Private
exports.deleteComment = async (req, res, next) => {
  try {
    const post = await BlogPost.findById(req.params.id);
    
    if (!post) {
      return res.status(404).json({ error: 'Post no encontrado' });
    }
    
    const comment = post.comments.id(req.params.commentId);
    
    if (!comment) {
      return res.status(404).json({ error: 'Comentario no encontrado' });
    }
    
    // Check if user can delete comment
    if (comment.user.toString() !== req.user._id && req.user.role !== 'administrador') {
      return res.status(403).json({ error: 'No autorizado para eliminar este comentario' });
    }
    
    comment.deleteOne();
    await post.save();
    
    res.json({
      success: true,
      message: 'Comentario eliminado'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Like/Unlike post
// @route   POST /api/blog/:id/like
// @access  Private
exports.toggleLike = async (req, res, next) => {
  try {
    const post = await BlogPost.findById(req.params.id);
    
    if (!post) {
      return res.status(404).json({ error: 'Post no encontrado' });
    }
    
    const userIndex = post.likes.indexOf(req.user._id);
    
    if (userIndex === -1) {
      post.likes.push(req.user._id);
    } else {
      post.likes.splice(userIndex, 1);
    }
    
    await post.save();
    
    res.json({
      success: true,
      likes: post.likes.length,
      liked: userIndex === -1
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete blog post
// @route   DELETE /api/blog/:id
// @access  Private/Admin
exports.deletePost = async (req, res, next) => {
  try {
    const post = await BlogPost.findById(req.params.id);
    
    if (!post) {
      return res.status(404).json({ error: 'Post no encontrado' });
    }
    
    await post.deleteOne();
    
    res.json({
      success: true,
      message: 'Post eliminado exitosamente'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Upload blog post image
// @route   POST /api/blog/:id/image
// @access  Private/Admin
exports.uploadPostImage = async (req, res, next) => {
  try {
    // TODO: Implement file upload logic
    res.status(501).json({
      success: false,
      error: 'Funcionalidad de carga de imágenes pendiente de implementación'
    });
  } catch (error) {
    next(error);
  }
};