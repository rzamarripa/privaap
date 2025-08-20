const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const proposalController = require('../controllers/proposal.controller');
const auth = require('../middlewares/auth');
const admin = require('../middlewares/admin');

// Get all proposals
router.get('/', auth, proposalController.getAllProposals);

// Get proposal by ID
router.get('/:id', auth, proposalController.getProposalById);

// Get proposals by status
router.get('/status/:status', auth, proposalController.getProposalsByStatus);

// Get proposals by user
router.get('/user/:userId', auth, proposalController.getProposalsByUser);

// Create new proposal
router.post('/',
  auth,
  [
    body('title').notEmpty().trim().withMessage('El título es requerido'),
    body('description').notEmpty().withMessage('La descripción es requerida'),
    body('category').notEmpty().withMessage('La categoría es requerida'),
    body('estimatedCost').optional().isNumeric().withMessage('El costo estimado debe ser numérico'),
    body('priority').optional().isIn(['baja', 'media', 'alta']).withMessage('Prioridad inválida')
  ],
  proposalController.createProposal
);

// Update proposal (admin or proposal author)
router.put('/:id',
  auth,
  [
    body('title').optional().notEmpty().trim().withMessage('El título no puede estar vacío'),
    body('description').optional().notEmpty().withMessage('La descripción no puede estar vacía'),
    body('category').optional().notEmpty().withMessage('La categoría no puede estar vacía'),
    body('estimatedCost').optional().isNumeric().withMessage('El costo estimado debe ser numérico'),
    body('priority').optional().isIn(['baja', 'media', 'alta']).withMessage('Prioridad inválida')
  ],
  proposalController.updateProposal
);

// Update proposal status (admin only)
router.patch('/:id/status',
  auth,
  admin,
  [
    body('status').isIn(['pendiente', 'en_revision', 'aprobada', 'rechazada', 'en_progreso', 'completada']).withMessage('Estado inválido'),
    body('adminComment').optional().trim()
  ],
  proposalController.updateProposalStatus
);

// Vote on proposal
router.post('/:id/vote',
  auth,
  [
    body('vote').isIn(['a_favor', 'en_contra', 'abstención']).withMessage('Voto inválido')
  ],
  proposalController.voteOnProposal
);

// Add comment to proposal
router.post('/:id/comments',
  auth,
  [
    body('content').notEmpty().trim().withMessage('El comentario no puede estar vacío')
  ],
  proposalController.addComment
);

// Delete comment (admin or comment author)
router.delete('/:id/comments/:commentId', auth, proposalController.deleteComment);

// Delete proposal (admin or proposal author)
router.delete('/:id', auth, proposalController.deleteProposal);

// Upload proposal attachment
router.post('/:id/attachment',
  auth,
  proposalController.uploadAttachment
);

module.exports = router;