const mongoose = require("mongoose");

const houseSchema = new mongoose.Schema(
  {
    houseNumber: {
      type: String,
      required: [true, "El número de casa es obligatorio"],
      trim: true,
    },
    communityId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Community",
      required: [true, "La comunidad es obligatoria"],
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Índices para optimizar consultas
houseSchema.index({ communityId: 1, houseNumber: 1 }, { unique: true });
houseSchema.index({ communityId: 1, isActive: 1 });

// Método para obtener información pública de la casa
houseSchema.methods.getPublicInfo = function () {
  return {
    id: this._id,
    houseNumber: this.houseNumber,
    communityId: this.communityId,
    isActive: this.isActive,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

// Middleware pre-save para validar que no exista otra casa con el mismo número en la misma comunidad
houseSchema.pre("save", async function (next) {
  if (this.isModified("houseNumber") || this.isModified("communityId")) {
    const existingHouse = await this.constructor.findOne({
      communityId: this.communityId,
      houseNumber: this.houseNumber,
      _id: { $ne: this._id },
    });

    if (existingHouse) {
      return next(
        new Error(
          `Ya existe una casa con el número ${this.houseNumber} en esta comunidad`
        )
      );
    }
  }
  next();
});

module.exports = mongoose.model("House", houseSchema);
