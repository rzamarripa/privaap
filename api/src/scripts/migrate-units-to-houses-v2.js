const mongoose = require("mongoose");

// Configuración de conexión a MongoDB
const MONGODB_URI =
  process.env.MONGODB_URI || "mongodb://localhost:27017/privapp";

async function migrateDatabaseV2() {
  try {
    console.log("🔌 Conectando a MongoDB...");
    await mongoose.connect(MONGODB_URI);
    console.log("✅ Conectado a MongoDB exitosamente");

    console.log("\n🔄 Iniciando migración V2 de 'unidades' a 'casas'...");

    // 1. Migrar Communities: totalUnits -> totalHouses
    console.log("\n📊 Migrando comunidades...");
    const communities = await mongoose.connection.db
      .collection("communities")
      .find({})
      .toArray();
    console.log(`Encontradas ${communities.length} comunidades`);

    for (const community of communities) {
      if (community.totalUnits !== undefined) {
        console.log(`Migrando comunidad: ${community.name}`);

        // Actualizar directamente en la base de datos
        await mongoose.connection.db.collection("communities").updateOne(
          { _id: community._id },
          {
            $set: { totalHouses: community.totalUnits },
            $unset: { totalUnits: "" },
          }
        );

        console.log(
          `✅ ${community.name}: totalUnits(${community.totalUnits}) -> totalHouses(${community.totalUnits})`
        );
      }
    }

    // 2. Migrar Users: apartment -> house
    console.log("\n👥 Migrando usuarios...");
    const users = await mongoose.connection.db
      .collection("users")
      .find({})
      .toArray();
    console.log(`Encontrados ${users.length} usuarios`);

    for (const user of users) {
      if (user.apartment !== undefined) {
        console.log(`Migrando usuario: ${user.name}`);

        // Actualizar directamente en la base de datos
        await mongoose.connection.db.collection("users").updateOne(
          { _id: user._id },
          {
            $set: { house: user.apartment },
            $unset: { apartment: "" },
          }
        );

        console.log(
          `✅ ${user.name}: apartment(${user.apartment}) -> house(${user.apartment})`
        );
      }
    }

    console.log("\n🎉 Migración V2 completada exitosamente!");
    console.log("\n📋 Resumen de cambios:");
    console.log(
      "- Communities: totalUnits -> totalHouses (eliminado totalUnits)"
    );
    console.log("- Users: apartment -> house (eliminado apartment)");
    console.log("\n⚠️  IMPORTANTE: Los campos antiguos han sido eliminados");
  } catch (error) {
    console.error("❌ Error durante la migración:", error);
  } finally {
    await mongoose.disconnect();
    console.log("\n🔌 Desconectado de MongoDB");
  }
}

// Ejecutar migración
migrateDatabaseV2();
