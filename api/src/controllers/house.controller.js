const House = require("../models/House.model.js");
const Community = require("../models/Community.model.js");

// Obtener todas las casas (solo para super admin)
exports.getAllHouses = async (req, res) => {
  try {
    const houses = await House.find().populate('communityId', 'name').sort({ communityId: 1, houseNumber: 1 });

    res.json({
      success: true,
      data: houses.map((house) => ({
        ...house.getPublicInfo(),
        communityName: house.communityId?.name || 'Sin comunidad'
      })),
      total: houses.length,
    });
  } catch (error) {
    console.error("Error en getAllHouses:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Obtener todas las casas de una comunidad
exports.getHousesByCommunity = async (req, res) => {
  try {
    const { communityId } = req.params;

    // Verificar que la comunidad existe
    const community = await Community.findById(communityId);
    if (!community) {
      return res.status(404).json({
        success: false,
        error: "Comunidad no encontrada",
      });
    }

    const houses = await House.find({
      communityId,
      isActive: true,
    }).sort({ houseNumber: 1 });

    res.json({
      success: true,
      data: houses.map((house) => house.getPublicInfo()),
      total: houses.length,
    });
  } catch (error) {
    console.error("Error en getHousesByCommunity:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Crear una nueva casa
exports.createHouse = async (req, res) => {
  try {
    const { houseNumber, communityId } = req.body;

    // Validaciones básicas
    if (!houseNumber || !communityId) {
      return res.status(400).json({
        success: false,
        error: "El número de casa y la comunidad son obligatorios",
      });
    }

    // Verificar que la comunidad existe
    const community = await Community.findById(communityId);
    if (!community) {
      return res.status(404).json({
        success: false,
        error: "Comunidad no encontrada",
      });
    }

    // Verificar que el número de casa no exceda el total de casas de la comunidad
    const existingHouses = await House.countDocuments({
      communityId,
      isActive: true,
    });
    if (existingHouses >= community.totalHouses) {
      return res.status(400).json({
        success: false,
        error: `No se pueden crear más casas. La comunidad tiene un límite de ${community.totalHouses} casas`,
      });
    }

    // Crear la casa
    const house = new House({
      houseNumber,
      communityId,
      isActive: true,
    });

    await house.save();

    res.status(201).json({
      success: true,
      data: house.getPublicInfo(),
      message: "Casa creada exitosamente",
    });
  } catch (error) {
    console.error("Error en createHouse:", error);

    if (error.message.includes("Ya existe una casa")) {
      return res.status(400).json({
        success: false,
        error: error.message,
      });
    }

    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Obtener una casa específica
exports.getHouseById = async (req, res) => {
  try {
    const { id } = req.params;

    const house = await House.findById(id);
    if (!house) {
      return res.status(404).json({
        success: false,
        error: "Casa no encontrada",
      });
    }

    res.json({
      success: true,
      data: house.getPublicInfo(),
    });
  } catch (error) {
    console.error("Error en getHouseById:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Actualizar una casa
exports.updateHouse = async (req, res) => {
  try {
    const { id } = req.params;
    const { houseNumber, isActive } = req.body;

    const house = await House.findById(id);
    if (!house) {
      return res.status(404).json({
        success: false,
        error: "Casa no encontrada",
      });
    }

    // Solo permitir actualizar número y estado
    if (houseNumber !== undefined) house.houseNumber = houseNumber;
    if (isActive !== undefined) house.isActive = isActive;

    await house.save();

    res.json({
      success: true,
      data: house.getPublicInfo(),
      message: "Casa actualizada exitosamente",
    });
  } catch (error) {
    console.error("Error en updateHouse:", error);

    if (error.message.includes("Ya existe una casa")) {
      return res.status(400).json({
        success: false,
        error: error.message,
      });
    }

    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};

// Eliminar una casa (desactivar)
exports.deleteHouse = async (req, res) => {
  try {
    const { id } = req.params;

    const house = await House.findById(id);
    if (!house) {
      return res.status(404).json({
        success: false,
        error: "Casa no encontrada",
      });
    }

    // En lugar de eliminar, desactivar
    house.isActive = false;
    await house.save();

    res.json({
      success: true,
      message: "Casa desactivada exitosamente",
    });
  } catch (error) {
    console.error("Error en deleteHouse:", error);
    res.status(500).json({
      success: false,
      error: "Error interno del servidor",
    });
  }
};
