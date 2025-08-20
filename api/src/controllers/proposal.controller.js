const { validationResult } = require('express-validator');
const Proposal = require('../models/Proposal.model');

// @desc    Get all proposals
// @route   GET /api/proposals
// @access  Private
exports.getAllProposals = async (req, res, next) => {
  try {
    const proposals = await Proposal.find()
      .populate('submittedBy', 'name email')
      .sort('-createdAt');
    
    res.json({
      success: true,
      count: proposals.length,
      data: proposals
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get proposal by ID
// @route   GET /api/proposals/:id
// @access  Private
exports.getProposalById = async (req, res, next) => {
  try {
    const proposal = await Proposal.findById(req.params.id)
      .populate('submittedBy', 'name email')
      .populate('comments.user', 'name')
      .populate('votes.user', 'name');
    
    if (!proposal) {
      return res.status(404).json({ error: 'Propuesta no encontrada' });
    }
    
    res.json({
      success: true,
      data: proposal
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get proposals by status
// @route   GET /api/proposals/status/:status
// @access  Private
exports.getProposalsByStatus = async (req, res, next) => {
  try {
    const proposals = await Proposal.find({ status: req.params.status })
      .populate('submittedBy', 'name email')
      .sort('-createdAt');
    
    res.json({
      success: true,
      count: proposals.length,
      data: proposals
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get proposals by user
// @route   GET /api/proposals/user/:userId
// @access  Private
exports.getProposalsByUser = async (req, res, next) => {
  try {
    const proposals = await Proposal.find({ submittedBy: req.params.userId })
      .populate('submittedBy', 'name email')
      .sort('-createdAt');
    
    res.json({
      success: true,
      count: proposals.length,
      data: proposals
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create new proposal
// @route   POST /api/proposals
// @access  Private
exports.createProposal = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const proposalData = {
      ...req.body,
      submittedBy: req.user._id
    };
    
    const proposal = await Proposal.create(proposalData);
    
    res.status(201).json({
      success: true,
      data: proposal
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update proposal
// @route   PUT /api/proposals/:id
// @access  Private
exports.updateProposal = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    let proposal = await Proposal.findById(req.params.id);
    
    if (!proposal) {
      return res.status(404).json({ error: 'Propuesta no encontrada' });
    }
    
    // Check if user can update
    if (proposal.submittedBy.toString() !== req.user._id && req.user.role !== 'administrador') {
      return res.status(403).json({ error: 'No autorizado para actualizar esta propuesta' });
    }
    
    proposal = await Proposal.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    
    res.json({
      success: true,
      data: proposal
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update proposal status
// @route   PATCH /api/proposals/:id/status
// @access  Private/Admin
exports.updateProposalStatus = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { status, adminComment } = req.body;
    
    const proposal = await Proposal.findByIdAndUpdate(
      req.params.id,
      { 
        status,
        adminComment,
        statusUpdatedAt: new Date()
      },
      { new: true, runValidators: true }
    );
    
    if (!proposal) {
      return res.status(404).json({ error: 'Propuesta no encontrada' });
    }
    
    res.json({
      success: true,
      data: proposal
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Vote on proposal
// @route   POST /api/proposals/:id/vote
// @access  Private
exports.voteOnProposal = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const proposal = await Proposal.findById(req.params.id);
    
    if (!proposal) {
      return res.status(404).json({ error: 'Propuesta no encontrada' });
    }
    
    // Check if user already voted
    const existingVoteIndex = proposal.votes.findIndex(
      v => v.user.toString() === req.user._id
    );
    
    if (existingVoteIndex !== -1) {
      // Update existing vote
      proposal.votes[existingVoteIndex].vote = req.body.vote;
    } else {
      // Add new vote
      proposal.votes.push({
        user: req.user._id,
        vote: req.body.vote
      });
    }
    
    await proposal.save();
    
    // Calculate vote summary
    const voteSummary = {
      a_favor: proposal.votes.filter(v => v.vote === 'a_favor').length,
      en_contra: proposal.votes.filter(v => v.vote === 'en_contra').length,
      abstencion: proposal.votes.filter(v => v.vote === 'abstención').length
    };
    
    res.json({
      success: true,
      voteSummary,
      userVote: req.body.vote
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add comment to proposal
// @route   POST /api/proposals/:id/comments
// @access  Private
exports.addComment = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const proposal = await Proposal.findById(req.params.id);
    
    if (!proposal) {
      return res.status(404).json({ error: 'Propuesta no encontrada' });
    }
    
    proposal.comments.push({
      user: req.user._id,
      content: req.body.content
    });
    
    await proposal.save();
    
    res.json({
      success: true,
      data: proposal.comments
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete comment
// @route   DELETE /api/proposals/:id/comments/:commentId
// @access  Private
exports.deleteComment = async (req, res, next) => {
  try {
    const proposal = await Proposal.findById(req.params.id);
    
    if (!proposal) {
      return res.status(404).json({ error: 'Propuesta no encontrada' });
    }
    
    const comment = proposal.comments.id(req.params.commentId);
    
    if (!comment) {
      return res.status(404).json({ error: 'Comentario no encontrado' });
    }
    
    // Check if user can delete comment
    if (comment.user.toString() !== req.user._id && req.user.role !== 'administrador') {
      return res.status(403).json({ error: 'No autorizado para eliminar este comentario' });
    }
    
    comment.deleteOne();
    await proposal.save();
    
    res.json({
      success: true,
      message: 'Comentario eliminado'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete proposal
// @route   DELETE /api/proposals/:id
// @access  Private
exports.deleteProposal = async (req, res, next) => {
  try {
    const proposal = await Proposal.findById(req.params.id);
    
    if (!proposal) {
      return res.status(404).json({ error: 'Propuesta no encontrada' });
    }
    
    // Check if user can delete
    if (proposal.submittedBy.toString() !== req.user._id && req.user.role !== 'administrador') {
      return res.status(403).json({ error: 'No autorizado para eliminar esta propuesta' });
    }
    
    await proposal.deleteOne();
    
    res.json({
      success: true,
      message: 'Propuesta eliminada exitosamente'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Upload proposal attachment
// @route   POST /api/proposals/:id/attachment
// @access  Private
exports.uploadAttachment = async (req, res, next) => {
  try {
    // TODO: Implement file upload logic
    res.status(501).json({
      success: false,
      error: 'Funcionalidad de carga de archivos pendiente de implementación'
    });
  } catch (error) {
    next(error);
  }
};