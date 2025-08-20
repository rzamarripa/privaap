const mongoose = require("mongoose");
const dotenv = require("dotenv");
const User = require("../models/User.model");

dotenv.config();

const seedUsers = async () => {
  try {
    // Conectar a MongoDB
    await mongoose.connect(
      process.env.MONGODB_URI || "mongodb://localhost:27017/privapp"
    );
    console.log("✅ MongoDB conectado");

    // Limpiar usuarios existentes
    await User.deleteMany({});
    console.log("🗑️  Usuarios existentes eliminados");

    // Crear usuarios de prueba
    const users = [
      {
        phoneNumber: "9999999999",
        password: "superadmin123",
        email: "superadmin@privada.com",
        name: "Super Administrador",
        role: "superAdmin",
        apartment: "S-001",
        isActive: true,
      },
      {
        phoneNumber: "1234567890",
        password: "admin123",
        email: "admin@privada.com",
        name: "Admin Principal",
        role: "administrador",
        apartment: "A-100",
        isActive: true,
      },
      {
        phoneNumber: "0987654321",
        password: "user123",
        email: "juan@example.com",
        name: "Juan Pérez",
        role: "residente",
        apartment: "B-201",
        isActive: true,
      },
      {
        phoneNumber: "5555555555",
        password: "maria123",
        email: "maria@example.com",
        name: "María García",
        role: "residente",
        apartment: "C-302",
        isActive: true,
      },
    ];

    // Crear usuarios uno por uno para que se ejecute el middleware de encriptación
    const createdUsers = [];
    for (const userData of users) {
      const user = await User.create(userData);
      createdUsers.push(user);
    }
    console.log(`✅ ${createdUsers.length} usuarios creados exitosamente`);

    console.log("\n📋 Usuarios disponibles para login:");
    console.log("================================");
    console.log("👑 SUPER ADMINISTRADOR:");
    console.log("   Teléfono: 9999999999");
    console.log("   Contraseña: superadmin123");
    console.log("   ⚠️  ACCESO TOTAL - Puede crear privadas");
    console.log("");
    console.log("👤 ADMINISTRADOR:");
    console.log("   Teléfono: 1234567890");
    console.log("   Contraseña: admin123");
    console.log("");
    console.log("👤 RESIDENTE 1:");
    console.log("   Teléfono: 0987654321");
    console.log("   Contraseña: user123");
    console.log("");
    console.log("👤 RESIDENTE 2:");
    console.log("   Teléfono: 5555555555");
    console.log("   Contraseña: maria123");
    console.log("================================\n");

    // Cerrar conexión
    await mongoose.connection.close();
    console.log("✅ Proceso completado");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  }
};

seedUsers();
