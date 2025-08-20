const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const blogController = require('../controllers/blog.controller');
const auth = require('../middlewares/auth');
const admin = require('../middlewares/admin');

// Get all blog posts
router.get('/', auth, blogController.getAllPosts);

// Get blog post by ID
router.get('/:id', auth, blogController.getPostById);

// Get posts by author
router.get('/author/:authorId', auth, blogController.getPostsByAuthor);

// Get posts by tag
router.get('/tag/:tag', auth, blogController.getPostsByTag);

// Create new blog post
router.post('/',
  auth,
  [
    body('title').notEmpty().trim().withMessage('El título es requerido'),
    body('content').notEmpty().withMessage('El contenido es requerido'),
    body('category').notEmpty().withMessage('La categoría es requerida'),
    body('tags').optional().isArray().withMessage('Las etiquetas deben ser un array'),
    body('isPublished').optional().isBoolean().withMessage('isPublished debe ser booleano')
  ],
  blogController.createPost
);

// Update blog post (admin only)
router.put('/:id',
  auth,
  admin,
  [
    body('title').optional().notEmpty().trim().withMessage('El título no puede estar vacío'),
    body('content').optional().notEmpty().withMessage('El contenido no puede estar vacío'),
    body('category').optional().notEmpty().withMessage('La categoría no puede estar vacía'),
    body('tags').optional().isArray().withMessage('Las etiquetas deben ser un array'),
    body('isPublished').optional().isBoolean().withMessage('isPublished debe ser booleano')
  ],
  blogController.updatePost
);

// Publish/Unpublish post (admin only)
router.patch('/:id/publish',
  auth,
  admin,
  [
    body('isPublished').isBoolean().withMessage('isPublished debe ser booleano')
  ],
  blogController.togglePublishStatus
);

// Add comment to post
router.post('/:id/comments',
  auth,
  [
    body('content').notEmpty().trim().withMessage('El comentario no puede estar vacío')
  ],
  blogController.addComment
);

// Delete comment (admin or comment author)
router.delete('/:id/comments/:commentId', auth, blogController.deleteComment);

// Like/Unlike post
router.post('/:id/like', auth, blogController.toggleLike);

// Delete blog post (admin only)
router.delete('/:id', auth, admin, blogController.deletePost);

// Upload blog post image
router.post('/:id/image',
  auth,
  admin,
  blogController.uploadPostImage
);

module.exports = router;