const { validationResult } = require("express-validator");
const Survey = require("../models/Survey.model");

// @desc    Get all surveys
// @route   GET /api/surveys
// @access  Private
exports.getAllSurveys = async (req, res, next) => {
  try {
    const surveys = await Survey.find()
      .populate("createdBy", "name email")
      .sort("-createdAt");

    // Transform surveys for Flutter compatibility
    const transformedSurveys = surveys.map((survey) => ({
      ...survey.toObject(),
      id: survey._id,
    }));

    res.json({
      success: true,
      count: surveys.length,
      data: transformedSurveys,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get survey by ID
// @route   GET /api/surveys/:id
// @access  Private
exports.getSurveyById = async (req, res, next) => {
  try {
    const survey = await Survey.findById(req.params.id)
      .populate("createdBy", "name email")
      .populate("responses.user", "name");

    if (!survey) {
      return res.status(404).json({ error: "Encuesta no encontrada" });
    }

    res.json({
      success: true,
      data: survey,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get active surveys
// @route   GET /api/surveys/status/active
// @access  Private
exports.getActiveSurveys = async (req, res, next) => {
  try {
    const now = new Date();

    const surveys = await Survey.find({
      startDate: { $lte: now },
      endDate: { $gte: now },
      isActive: true,
    })
      .populate("createdBy", "name email")
      .sort("-createdAt");

    res.json({
      success: true,
      count: surveys.length,
      data: surveys,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get survey results
// @route   GET /api/surveys/:id/results
// @access  Private/Admin
exports.getSurveyResults = async (req, res, next) => {
  try {
    const survey = await Survey.findById(req.params.id).populate(
      "responses.user",
      "name email"
    );

    if (!survey) {
      return res.status(404).json({ error: "Encuesta no encontrada" });
    }

    // Process results
    const results = {
      survey: {
        id: survey._id,
        title: survey.title,
        description: survey.description,
        totalResponses: survey.responses.length,
      },
      questions: {},
    };

    // Initialize question results
    survey.questions.forEach((question) => {
      results.questions[question._id] = {
        text: question.text,
        type: question.type,
        responses: [],
        summary: {},
      };

      if (question.type === "multiple_choice") {
        question.options.forEach((option) => {
          results.questions[question._id].summary[option] = 0;
        });
      }
    });

    // Process responses
    survey.responses.forEach((response) => {
      response.answers.forEach((answer) => {
        const questionId = answer.questionId.toString();
        if (results.questions[questionId]) {
          results.questions[questionId].responses.push({
            user: response.user.name,
            answer: answer.answer,
          });

          // Update summary for multiple choice
          const question = survey.questions.find(
            (q) => q._id.toString() === questionId
          );
          if (question && question.type === "multiple_choice") {
            results.questions[questionId].summary[answer.answer] =
              (results.questions[questionId].summary[answer.answer] || 0) + 1;
          }
        }
      });
    });

    res.json({
      success: true,
      data: results,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create new survey
// @route   POST /api/surveys
// @access  Private/Admin
exports.createSurvey = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const errorMessages = errors
        .array()
        .map((err) => err.msg)
        .join(", ");
      return res.status(400).json({
        success: false,
        message: errorMessages,
        errors: errors.array(),
      });
    }

    // Clean the request data - remove any invalid _id that Flutter might send
    const cleanBody = { ...req.body };
    if (cleanBody._id) delete cleanBody._id;
    if (cleanBody.id) delete cleanBody.id;

    // Validate required fields for Flutter's simple model
    if (!cleanBody.question || !cleanBody.options) {
      return res.status(400).json({
        success: false,
        message: "La pregunta y las opciones son requeridas",
      });
    }

    // Validate options array
    if (!Array.isArray(cleanBody.options) || cleanBody.options.length < 2) {
      return res.status(400).json({
        success: false,
        message: "Debe incluir al menos 2 opciones para la encuesta",
      });
    }

    // Validate that options are not empty
    const validOptions = cleanBody.options.filter((option) => {
      const text =
        typeof option === "string" ? option : option.text || option.title;
      return text && text.trim().length > 0;
    });

    if (validOptions.length < 2) {
      return res.status(400).json({
        success: false,
        message: "Todas las opciones deben tener texto válido",
      });
    }

    // Create survey data matching the Survey model structure
    const surveyData = {
      question: cleanBody.question,
      options: validOptions.map((option) => ({
        text: typeof option === "string" ? option : option.text || option.title,
        emoji: typeof option === "object" && option.emoji ? option.emoji : null,
      })),
      createdBy: req.user._id,
      allowMultipleAnswers: cleanBody.allowMultipleAnswers || false,
      isAnonymous: cleanBody.isAnonymous || false,
      expiresAt: cleanBody.expiresAt ? new Date(cleanBody.expiresAt) : null,
    };

    const survey = await Survey.create(surveyData);

    // Transform response for Flutter compatibility
    const responseData = {
      ...survey.toObject(),
      id: survey._id,
    };

    res.status(201).json({
      success: true,
      message: "Encuesta creada exitosamente",
      data: responseData,
    });
  } catch (error) {
    // Handle Mongoose validation errors
    if (error.name === "ValidationError") {
      const errorMessages = Object.values(error.errors)
        .map((err) => err.message)
        .join(", ");
      return res.status(400).json({
        success: false,
        message: errorMessages,
      });
    }

    // Handle other specific errors
    if (error.name === "CastError") {
      return res.status(400).json({
        success: false,
        message: "ID de usuario inválido",
      });
    }

    next(error);
  }
};

// @desc    Update survey
// @route   PUT /api/surveys/:id
// @access  Private/Admin
exports.updateSurvey = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const errorMessages = errors
        .array()
        .map((err) => err.msg)
        .join(", ");
      return res.status(400).json({
        success: false,
        message: errorMessages,
      });
    }

    // Clean the request data
    const cleanBody = { ...req.body };
    if (cleanBody._id) delete cleanBody._id;
    if (cleanBody.id) delete cleanBody.id;

    // Validate required fields
    if (!cleanBody.question || !cleanBody.options) {
      return res.status(400).json({
        success: false,
        message: "La pregunta y las opciones son requeridas",
      });
    }

    // Validate options array
    if (!Array.isArray(cleanBody.options) || cleanBody.options.length < 2) {
      return res.status(400).json({
        success: false,
        message: "Debe incluir al menos 2 opciones para la encuesta",
      });
    }

    // Validate that options are not empty
    const validOptions = cleanBody.options.filter((option) => {
      const text =
        typeof option === "string" ? option : option.text || option.title;
      return text && text.trim().length > 0;
    });

    if (validOptions.length < 2) {
      return res.status(400).json({
        success: false,
        message: "Todas las opciones deben tener texto válido",
      });
    }

    // Prepare update data
    const updateData = {
      question: cleanBody.question,
      options: validOptions.map((option, index) => ({
        _id: option._id || option.id, // Preservar ID original si existe
        text: typeof option === "string" ? option : option.text || option.title,
        emoji: typeof option === "object" && option.emoji ? option.emoji : null,
      })),
      allowMultipleAnswers: cleanBody.allowMultipleAnswers || false,
      isAnonymous: cleanBody.isAnonymous || false,
      expiresAt: cleanBody.expiresAt ? new Date(cleanBody.expiresAt) : null,
      votes: [], // Resetear todos los votos para permitir votar de nuevo
    };

    const survey = await Survey.findByIdAndUpdate(req.params.id, updateData, {
      new: true,
      runValidators: true,
    });

    if (!survey) {
      return res.status(404).json({
        success: false,
        message: "Encuesta no encontrada",
      });
    }

    // Transform response for Flutter compatibility
    const responseData = {
      ...survey.toObject(),
      id: survey._id,
    };

    res.json({
      success: true,
      message: "Encuesta actualizada exitosamente",
      data: responseData,
    });
  } catch (error) {
    // Handle Mongoose validation errors
    if (error.name === "ValidationError") {
      const errorMessages = Object.values(error.errors)
        .map((err) => err.message)
        .join(", ");
      return res.status(400).json({
        success: false,
        message: errorMessages,
      });
    }

    next(error);
  }
};

// @desc    Submit survey response
// @route   POST /api/surveys/:id/responses
// @access  Private
exports.submitResponse = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const survey = await Survey.findById(req.params.id);

    if (!survey) {
      return res.status(404).json({ error: "Encuesta no encontrada" });
    }

    // Check if survey is active
    const now = new Date();
    if (survey.startDate > now || survey.endDate < now || !survey.isActive) {
      return res.status(400).json({ error: "La encuesta no está activa" });
    }

    // Check if user already responded
    const existingResponse = survey.responses.find(
      (r) => r.user.toString() === req.user._id
    );

    if (existingResponse) {
      return res
        .status(400)
        .json({ error: "Ya has respondido a esta encuesta" });
    }

    // Add response
    survey.responses.push({
      user: req.user._id,
      answers: req.body.responses,
    });

    await survey.save();

    res.json({
      success: true,
      message: "Respuesta enviada exitosamente",
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Close survey
// @route   PATCH /api/surveys/:id/close
// @access  Private/Admin
exports.closeSurvey = async (req, res, next) => {
  try {
    const survey = await Survey.findByIdAndUpdate(
      req.params.id,
      { isActive: false },
      { new: true, runValidators: true }
    );

    if (!survey) {
      return res.status(404).json({ error: "Encuesta no encontrada" });
    }

    res.json({
      success: true,
      data: survey,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete survey
// @route   DELETE /api/surveys/:id
// @access  Private/Admin
exports.deleteSurvey = async (req, res, next) => {
  try {
    const survey = await Survey.findById(req.params.id);

    if (!survey) {
      return res.status(404).json({ error: "Encuesta no encontrada" });
    }

    await survey.deleteOne();

    res.json({
      success: true,
      message: "Encuesta eliminada exitosamente",
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Vote in survey (simplified for Flutter compatibility)
// @route   POST /api/surveys/:id/vote
// @access  Private
exports.voteSurvey = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const errorMessages = errors
        .array()
        .map((err) => err.msg)
        .join(", ");
      return res.status(400).json({
        success: false,
        message: errorMessages,
      });
    }

    const { selectedOptions } = req.body;
    const surveyId = req.params.id;
    const userId = req.user._id;

    const survey = await Survey.findById(surveyId);

    if (!survey) {
      return res.status(404).json({
        success: false,
        message: "Encuesta no encontrada",
      });
    }

    // Check if survey is active
    if (!survey.isActive) {
      return res.status(400).json({
        success: false,
        message: "La encuesta no está activa",
      });
    }

    // Check if survey has expired
    const now = new Date();
    if (survey.expiresAt && new Date(survey.expiresAt) < now) {
      return res.status(400).json({
        success: false,
        message: "La encuesta ha expirado",
      });
    }

    // Check if user has already voted
    if (survey.hasUserVoted(userId)) {
      return res.status(400).json({
        success: false,
        message: "Ya has votado en esta encuesta",
      });
    }

    // Validate selected options
    if (!Array.isArray(selectedOptions) || selectedOptions.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Debe seleccionar al menos una opción",
      });
    }

    // Convert selectedOptions (which are option IDs from Flutter) to ObjectIds
    const selectedOptionIds = selectedOptions
      .map((optionId) => {
        // Find the option in the survey's options array
        const option = survey.options.find(
          (opt) => opt._id.toString() === optionId.toString()
        );
        return option ? option._id : null;
      })
      .filter((id) => id !== null);

    if (selectedOptionIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Las opciones seleccionadas no son válidas",
      });
    }

    // Check if multiple answers are allowed
    if (selectedOptionIds.length > 1 && !survey.allowMultipleAnswers) {
      return res.status(400).json({
        success: false,
        message: "Esta encuesta solo permite una respuesta",
      });
    }

    // Add the vote
    const vote = {
      user: userId,
      selectedOptions: selectedOptionIds,
      votedAt: new Date(),
    };

    survey.votes.push(vote);
    await survey.save();

    res.status(201).json({
      success: true,
      message: "Voto registrado exitosamente",
      data: {
        surveyId: survey._id,
        userId: userId,
        selectedOptions: selectedOptionIds,
      },
    });
  } catch (error) {
    // Handle validation errors
    if (error.name === "ValidationError") {
      const errorMessages = Object.values(error.errors)
        .map((err) => err.message)
        .join(", ");
      return res.status(400).json({
        success: false,
        message: errorMessages,
      });
    }

    next(error);
  }
};
