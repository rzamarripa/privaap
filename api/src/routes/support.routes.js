const express = require("express");
const router = express.Router();
const { body } = require("express-validator");
const supportController = require("../controllers/support.controller");
const auth = require("../middlewares/auth");
const admin = require("../middlewares/admin");
const multer = require("multer");
const path = require("path");

// Configuración de multer para subir archivos
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "uploads/support/");
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(
      null,
      file.fieldname + "-" + uniqueSuffix + path.extname(file.originalname)
    );
  },
});

const fileFilter = (req, file, cb) => {
  console.log('🔍 DEBUG fileFilter - Archivo recibido:');
  console.log('  - Nombre:', file.originalname);
  console.log('  - MIME Type:', file.mimetype);
  console.log('  - Tamaño:', file.size);
  
  // Permitir imágenes y algunos tipos adicionales
  const allowedMimeTypes = [
    'image/jpeg',
    'image/jpg', 
    'image/png',
    'image/gif',
    'image/webp',
    'image/bmp',
    'image/tiff'
  ];
  
  if (file.mimetype.startsWith("image/") || allowedMimeTypes.includes(file.mimetype)) {
    console.log('✅ Archivo aceptado:', file.mimetype);
    cb(null, true);
  } else {
    console.log('❌ Archivo rechazado:', file.mimetype);
    cb(new Error(`Tipo de archivo no permitido: ${file.mimetype}. Solo se permiten imágenes.`), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB máximo
  },
});

// Validaciones para crear ticket
const createTicketValidation = [
  body("userName")
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage("El nombre debe tener entre 2 y 100 caracteres"),

  body("userEmail").isEmail().normalizeEmail().withMessage("Email inválido"),

  body("userPhone")
    .optional()
    .trim()
    .isLength({ min: 10, max: 20 })
    .withMessage("El teléfono debe tener entre 10 y 20 caracteres"),

  body("communityName")
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage(
      "El nombre de la comunidad debe tener entre 2 y 100 caracteres"
    ),

  body("subject")
    .trim()
    .isLength({ min: 10, max: 200 })
    .withMessage("El asunto debe tener entre 10 y 200 caracteres"),

  body("category")
    .isIn(["technical", "bug", "feature", "account", "billing", "other"])
    .withMessage("Categoría no válida"),

  body("description")
    .trim()
    .isLength({ min: 20, max: 2000 })
    .withMessage("La descripción debe tener entre 20 y 2000 caracteres"),

  body("reproductionSteps")
    .optional()
    .trim()
    .isLength({ max: 1000 })
    .withMessage("Los pasos de reproducción no pueden exceder 1000 caracteres"),

  body("attachments")
    .optional()
    .isArray({ max: 3 })
    .withMessage("Máximo 3 adjuntos permitidos"),

  body("deviceType")
    .isIn(["Android", "iOS"])
    .withMessage("Tipo de dispositivo no válido"),

  body("appVersion")
    .trim()
    .isLength({ min: 1, max: 20 })
    .withMessage("La versión de la app debe tener entre 1 y 20 caracteres"),
];

// Validaciones para actualizar ticket
const updateTicketValidation = [
  body("status")
    .optional()
    .isIn(["pending", "in_progress", "resolved", "closed"])
    .withMessage("Estado no válido"),

  body("assignedTo")
    .optional()
    .isMongoId()
    .withMessage("ID de usuario asignado inválido"),

  body("response")
    .optional()
    .trim()
    .isLength({ min: 1, max: 2000 })
    .withMessage("La respuesta debe tener entre 1 y 2000 caracteres"),
];

// Validaciones para responder ticket
const respondTicketValidation = [
  body("response")
    .trim()
    .isLength({ min: 1, max: 2000 })
    .withMessage("La respuesta debe tener entre 1 y 2000 caracteres"),
];

// Rutas públicas (requieren autenticación)
router.post(
  "/tickets",
  auth,
  createTicketValidation,
  supportController.createTicket
);
router.get("/tickets/user", auth, supportController.getUserTickets);
router.get("/tickets/:id", auth, supportController.getTicketById);

// Ruta para subir archivos adjuntos
router.post("/upload", auth, (req, res, next) => {
  upload.single("attachment")(req, res, (err) => {
    if (err) {
      console.error("❌ Error en upload:", err.message);
      return res.status(400).json({
        success: false,
        error: err.message,
      });
    }

    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          error: "No se proporcionó ningún archivo",
        });
      }

      console.log('✅ Archivo subido exitosamente:');
      console.log('  - Nombre original:', req.file.originalname);
      console.log('  - Nombre guardado:', req.file.filename);
      console.log('  - Tamaño:', req.file.size);
      console.log('  - MIME Type:', req.file.mimetype);

      // Construir la URL del archivo
      const fileUrl = `${req.protocol}://${req.get("host")}/uploads/support/${
        req.file.filename
      }`;

      res.json({
        success: true,
        message: "Archivo subido exitosamente",
        data: {
          filename: req.file.filename,
          originalName: req.file.originalname,
          size: req.file.size,
          url: fileUrl,
        },
      });
    } catch (error) {
      console.error("❌ Error interno al procesar archivo:", error);
      res.status(500).json({
        success: false,
        error: "Error interno del servidor",
      });
    }
  });
});

// Rutas de administrador
router.get("/tickets", auth, admin, supportController.getAllTickets);
router.put(
  "/tickets/:id",
  auth,
  admin,
  updateTicketValidation,
  supportController.updateTicket
);
router.post("/tickets/:id/assign", auth, admin, supportController.assignTicket);
router.post(
  "/tickets/:id/respond",
  auth,
  admin,
  respondTicketValidation,
  supportController.respondToTicket
);
router.post("/tickets/:id/close", auth, admin, supportController.closeTicket);
router.get("/stats", auth, admin, supportController.getTicketStats);

module.exports = router;
