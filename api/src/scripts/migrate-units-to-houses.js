const mongoose = require("mongoose");
const Community = require("../models/Community.model");
const User = require("../models/User.model");

// Configuración de conexión a MongoDB
const MONGODB_URI =
  process.env.MONGODB_URI || "mongodb://localhost:27017/privapp";

async function migrateDatabase() {
  try {
    console.log("🔌 Conectando a MongoDB...");
    await mongoose.connect(MONGODB_URI);
    console.log("✅ Conectado a MongoDB exitosamente");

    console.log('\n🔄 Iniciando migración de "unidades" a "casas"...');

    // 1. Migrar Communities: totalUnits -> totalHouses
    console.log("\n📊 Migrando comunidades...");
    const communities = await Community.find({});
    console.log(`Encontradas ${communities.length} comunidades`);

    for (const community of communities) {
      if (community.totalUnits !== undefined) {
        console.log(`Migrando comunidad: ${community.name}`);

        // Crear nuevo campo totalHouses
        community.totalHouses = community.totalUnits;

        // Eliminar campo antiguo totalUnits
        community.totalUnits = undefined;

        // Marcar como modificado para que se guarde
        community.markModified("totalHouses");

        await community.save();
        console.log(`✅ ${community.name}: totalUnits -> totalHouses`);
      }
    }

    // 2. Migrar Users: apartment -> house
    console.log("\n👥 Migrando usuarios...");
    const users = await User.find({});
    console.log(`Encontrados ${users.length} usuarios`);

    for (const user of users) {
      if (user.apartment !== undefined) {
        console.log(`Migrando usuario: ${user.name}`);

        // Crear nuevo campo house
        user.house = user.apartment;

        // Eliminar campo antiguo apartment
        user.apartment = undefined;

        // Marcar como modificado para que se guarde
        user.markModified("house");

        await user.save();
        console.log(`✅ ${user.name}: apartment -> house`);
      }
    }

    console.log("\n🎉 Migración completada exitosamente!");
    console.log("\n📋 Resumen de cambios:");
    console.log("- Communities: totalUnits -> totalHouses");
    console.log("- Users: apartment -> house");
    console.log(
      "\n⚠️  IMPORTANTE: Actualiza tu código para usar los nuevos nombres de campos"
    );
  } catch (error) {
    console.error("❌ Error durante la migración:", error);
  } finally {
    await mongoose.disconnect();
    console.log("\n🔌 Desconectado de MongoDB");
  }
}

// Ejecutar migración
migrateDatabase();
