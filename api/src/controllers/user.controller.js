const { validationResult } = require("express-validator");
const User = require("../models/User.model");
const multer = require("multer");
const path = require("path");

// Configure multer for image uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/profiles");
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(
      null,
      `profile-${req.params.id}-${uniqueSuffix}${path.extname(
        file.originalname
      )}`
    );
  },
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    const filetypes = /jpeg|jpg|png|gif/;
    const mimetype = filetypes.test(file.mimetype);
    const extname = filetypes.test(
      path.extname(file.originalname).toLowerCase()
    );

    if (mimetype && extname) {
      return cb(null, true);
    }
    cb(new Error("Solo se permiten imágenes"));
  },
}).single("profileImage");

// @desc    Get all users
// @route   GET /api/users
// @access  Private/Admin
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find().select("-password");

    res.json({
      success: true,
      count: users.length,
      data: users,
    });
  } catch (error) {
    console.error("Get all users error:", error);
    res.status(500).json({ error: "Error al obtener usuarios" });
  }
};

// @desc    Create new user
// @route   POST /api/users
// @access  Private/Admin
exports.createUser = async (req, res) => {
  try {
    console.log("=== DEBUG: createUser iniciado ===");
    console.log("req.body:", req.body);

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log("Errores de validación:", errors.array());
      return res.status(400).json({
        success: false,
        error: "Datos de entrada inválidos",
        details: errors.array(),
      });
    }

    const {
      name,
      email,
      phoneNumber,
      password,
      role,
      house,
      communityId,
      isActive = true,
    } = req.body;

    console.log("Datos extraídos:", {
      name,
      email,
      phoneNumber,
      role,
      house,
      communityId,
      isActive,
    });

    // Check if email already exists
    const existingEmail = await User.findOne({ email });
    if (existingEmail) {
      console.log("Email ya existe:", email);
      return res.status(400).json({
        success: false,
        error: "El email ya está registrado",
      });
    }

    // Check if phone number already exists
    const existingPhone = await User.findOne({ phoneNumber });
    if (existingPhone) {
      console.log("Teléfono ya existe:", phoneNumber);
      return res.status(400).json({
        success: false,
        error: "El número de teléfono ya está registrado",
      });
    }

    console.log("Creando nuevo usuario...");

    // Create new user
    const user = new User({
      name,
      email,
      phoneNumber,
      password,
      role,
      house,
      communityId,
      isActive,
    });

    console.log("Usuario creado, guardando...");
    await user.save();
    console.log("Usuario guardado exitosamente, ID:", user._id);

    // Return user without password
    const userResponse = user.toObject();
    delete userResponse.password;

    res.status(201).json({
      success: true,
      message: "Usuario creado exitosamente",
      data: userResponse,
      userId: user._id,
    });

    console.log("=== DEBUG: createUser completado ===");
  } catch (error) {
    console.error("Create user error:", error);
    console.error("Error stack:", error.stack);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor al crear usuario",
    });
  }
};

// @desc    Get user by ID
// @route   GET /api/users/:id
// @access  Private
exports.getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select("-password");

    if (!user) {
      return res.status(404).json({ error: "Usuario no encontrado" });
    }

    // Check if user can access this profile
    if (req.user._id !== req.params.id && req.user.role !== "administrador") {
      return res
        .status(403)
        .json({ error: "No autorizado para ver este perfil" });
    }

    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error("Get user by ID error:", error);
    res.status(500).json({ error: "Error al obtener usuario" });
  }
};

// @desc    Update user
// @route   PUT /api/users/:id
// @access  Private
exports.updateUser = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    // Check if user can update this profile
    if (req.user._id !== req.params.id && req.user.role !== "administrador") {
      return res
        .status(403)
        .json({ error: "No autorizado para actualizar este perfil" });
    }

    const { name, email, phoneNumber, house } = req.body;

    // Check if email or phone already exists
    if (email || phoneNumber) {
      const existingUser = await User.findOne({
        $and: [
          { _id: { $ne: req.params.id } },
          { $or: [email ? { email } : {}, phoneNumber ? { phoneNumber } : {}] },
        ],
      });

      if (existingUser) {
        return res.status(400).json({
          error: "El email o número de teléfono ya está en uso",
        });
      }
    }

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { name, email, phoneNumber, house },
      { new: true, runValidators: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({ error: "Usuario no encontrado" });
    }

    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error("Update user error:", error);
    res.status(500).json({ error: "Error al actualizar usuario" });
  }
};

// @desc    Update user role
// @route   PATCH /api/users/:id/role
// @access  Private/Admin
exports.updateUserRole = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { role } = req.body;

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { role },
      { new: true, runValidators: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({ error: "Usuario no encontrado" });
    }

    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error("Update user role error:", error);
    res.status(500).json({ error: "Error al actualizar rol de usuario" });
  }
};

// @desc    Update user status
// @route   PATCH /api/users/:id/status
// @access  Private/Admin
exports.updateUserStatus = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { isActive } = req.body;

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isActive },
      { new: true, runValidators: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({ error: "Usuario no encontrado" });
    }

    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error("Update user status error:", error);
    res.status(500).json({ error: "Error al actualizar estado de usuario" });
  }
};

// @desc    Delete user
// @route   DELETE /api/users/:id
// @access  Private/Admin
exports.deleteUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({ error: "Usuario no encontrado" });
    }

    // Don't allow deleting the last admin
    if (user.role === "administrador") {
      const adminCount = await User.countDocuments({ role: "administrador" });
      if (adminCount <= 1) {
        return res.status(400).json({
          error: "No se puede eliminar el último administrador",
        });
      }
    }

    await user.deleteOne();

    res.json({
      success: true,
      message: "Usuario eliminado exitosamente",
    });
  } catch (error) {
    console.error("Delete user error:", error);
    res.status(500).json({ error: "Error al eliminar usuario" });
  }
};

// @desc    Upload profile image
// @route   POST /api/users/:id/profile-image
// @access  Private
exports.uploadProfileImage = async (req, res) => {
  upload(req, res, async (err) => {
    if (err) {
      console.error("Upload error:", err);
      return res.status(400).json({ error: err.message });
    }

    if (!req.file) {
      return res.status(400).json({ error: "Por favor selecciona una imagen" });
    }

    try {
      // Check if user can update this profile
      if (req.user._id !== req.params.id && req.user.role !== "administrador") {
        return res
          .status(403)
          .json({ error: "No autorizado para actualizar este perfil" });
      }

      const user = await User.findByIdAndUpdate(
        req.params.id,
        { profileImage: `/uploads/profiles/${req.file.filename}` },
        { new: true, runValidators: true }
      ).select("-password");

      if (!user) {
        return res.status(404).json({ error: "Usuario no encontrado" });
      }

      res.json({
        success: true,
        data: user,
      });
    } catch (error) {
      console.error("Update profile image error:", error);
      res.status(500).json({ error: "Error al actualizar imagen de perfil" });
    }
  });
};

// @desc    Change user password (admin only)
// @route   PATCH /api/users/:id/password
// @access  Private/Admin
exports.changeUserPassword = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false,
        error: "Datos de entrada inválidos",
        details: errors.array() 
      });
    }

    const { newPassword } = req.body;

    // Verificar que el usuario que hace la petición sea super admin
    if (req.user.role !== "superAdmin") {
      return res.status(403).json({
        success: false,
        error: "Solo los super administradores pueden cambiar contraseñas de otros usuarios",
      });
    }

    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({ 
        success: false,
        error: "Usuario no encontrado" 
      });
    }

    // No permitir cambiar la contraseña de otro super admin
    if (user.role === "superAdmin" && user._id.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        error: "No se puede cambiar la contraseña de otro super administrador",
      });
    }

    // Actualizar la contraseña
    user.password = newPassword;
    await user.save();

    console.log(`Password changed for user ${user.name} (${user.email}) by super admin ${req.user.name}`);

    res.json({
      success: true,
      message: `Contraseña actualizada exitosamente para ${user.name}`,
    });
  } catch (error) {
    console.error("Change user password error:", error);
    res.status(500).json({ 
      success: false,
      error: "Error interno del servidor al cambiar contraseña" 
    });
  }
};
