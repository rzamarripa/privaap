const express = require("express");
const router = express.Router();
const { body } = require("express-validator");
const surveyController = require("../controllers/survey.controller");
const auth = require("../middlewares/auth");
const admin = require("../middlewares/admin");

// Get all surveys
router.get("/", auth, surveyController.getAllSurveys);

// Get survey by ID
router.get("/:id", auth, surveyController.getSurveyById);

// Get active surveys
router.get("/status/active", auth, surveyController.getActiveSurveys);

// Get survey results (admin only)
router.get("/:id/results", auth, admin, surveyController.getSurveyResults);

// Create new survey
router.post(
  "/",
  auth,
  [
    body("question").notEmpty().trim().withMessage("La pregunta es requerida"),
    body("options")
      .isArray({ min: 2 })
      .withMessage("Debe incluir al menos 2 opciones"),
    body("options.*.text")
      .notEmpty()
      .withMessage("El texto de la opción es requerido"),
    body("allowMultipleAnswers")
      .optional()
      .isBoolean()
      .withMessage("allowMultipleAnswers debe ser un booleano"),
    body("isAnonymous")
      .optional()
      .isBoolean()
      .withMessage("isAnonymous debe ser un booleano"),
    body("expiresAt")
      .optional()
      .custom((value) => {
        if (value === null || value === undefined) return true;
        if (typeof value === "string" && value.trim() === "") return true;
        // Si es string, verificar que sea una fecha válida
        if (typeof value === "string") {
          const date = new Date(value);
          return !isNaN(date.getTime());
        }
        // Si es Date object, verificar que sea válido
        if (value instanceof Date) {
          return !isNaN(value.getTime());
        }
        return false;
      })
      .withMessage("Fecha de expiración inválida"),
  ],
  surveyController.createSurvey
);

// Update survey (admin only)
router.put(
  "/:id",
  auth,
  admin,
  [
    body("title")
      .optional()
      .notEmpty()
      .trim()
      .withMessage("El título no puede estar vacío"),
    body("description").optional().trim(),
    body("questions")
      .optional()
      .isArray({ min: 1 })
      .withMessage("Debe incluir al menos una pregunta"),
    body("startDate")
      .optional()
      .isISO8601()
      .withMessage("Fecha de inicio inválida"),
    body("endDate").optional().isISO8601().withMessage("Fecha de fin inválida"),
  ],
  surveyController.updateSurvey
);

// Submit survey response
router.post(
  "/:id/responses",
  auth,
  [
    body("responses")
      .isArray()
      .withMessage("Las respuestas deben ser un array"),
    body("responses.*.questionId")
      .notEmpty()
      .withMessage("ID de pregunta requerido"),
    body("responses.*.answer").notEmpty().withMessage("Respuesta requerida"),
  ],
  surveyController.submitResponse
);

// Vote in survey (simple voting for Flutter compatibility)
router.post(
  "/:id/vote",
  auth,
  [
    body("selectedOptions")
      .isArray()
      .withMessage("Opciones seleccionadas requeridas"),
    body("selectedOptions")
      .notEmpty()
      .withMessage("Debe seleccionar al menos una opción"),
  ],
  surveyController.voteSurvey
);

// Close survey (admin only)
router.patch("/:id/close", auth, admin, surveyController.closeSurvey);

// Delete survey (admin only)
router.delete("/:id", auth, admin, surveyController.deleteSurvey);

module.exports = router;
