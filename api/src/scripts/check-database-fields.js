const mongoose = require("mongoose");

// Configuración de conexión a MongoDB
const MONGODB_URI =
  process.env.MONGODB_URI || "mongodb://localhost:27017/privapp";

async function checkDatabaseFields() {
  try {
    console.log("🔌 Conectando a MongoDB...");
    await mongoose.connect(MONGODB_URI);
    console.log("✅ Conectado a MongoDB exitosamente");

    console.log("\n🔍 Revisando campos en la base de datos...");

    // 1. Revisar Communities
    console.log("\n📊 Revisando colección Communities...");
    const communities = await mongoose.connection.db
      .collection("communities")
      .find({})
      .limit(1)
      .toArray();

    if (communities.length > 0) {
      const community = communities[0];
      console.log("📋 Campos encontrados en Communities:");
      Object.keys(community).forEach((key) => {
        console.log(
          `  - ${key}: ${typeof community[key]} = ${JSON.stringify(
            community[key]
          )}`
        );
      });
    } else {
      console.log("❌ No se encontraron comunidades");
    }

    // 2. Revisar Users
    console.log("\n👥 Revisando colección Users...");
    const users = await mongoose.connection.db
      .collection("users")
      .find({})
      .limit(1)
      .toArray();

    if (users.length > 0) {
      const user = users[0];
      console.log("📋 Campos encontrados en Users:");
      Object.keys(user).forEach((key) => {
        console.log(
          `  - ${key}: ${typeof user[key]} = ${JSON.stringify(user[key])}`
        );
      });
    } else {
      console.log("❌ No se encontraron usuarios");
    }

    // 3. Buscar campos específicos
    console.log("\n🔍 Buscando campos específicos...");

    // Buscar campos que contengan "unit" o "apartment"
    const communitiesWithUnits = await mongoose.connection.db
      .collection("communities")
      .find({
        $or: [
          { totalUnits: { $exists: true } },
          { totalHouses: { $exists: true } },
        ],
      })
      .toArray();

    console.log(
      `📊 Comunidades con campos de unidades: ${communitiesWithUnits.length}`
    );
    communitiesWithUnits.forEach((comm) => {
      console.log(
        `  - ${comm.name}: totalUnits=${comm.totalUnits}, totalHouses=${comm.totalHouses}`
      );
    });

    const usersWithApartments = await mongoose.connection.db
      .collection("users")
      .find({
        $or: [{ apartment: { $exists: true } }, { house: { $exists: true } }],
      })
      .toArray();

    console.log(
      `👥 Usuarios con campos de apartamento: ${usersWithApartments.length}`
    );
    usersWithApartments.forEach((user) => {
      console.log(
        `  - ${user.name}: apartment=${user.apartment}, house=${user.house}`
      );
    });
  } catch (error) {
    console.error("❌ Error durante la revisión:", error);
  } finally {
    await mongoose.disconnect();
    console.log("\n🔌 Desconectado de MongoDB");
  }
}

// Ejecutar revisión
checkDatabaseFields();
