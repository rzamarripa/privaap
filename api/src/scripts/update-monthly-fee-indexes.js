require("dotenv").config();
const mongoose = require("mongoose");
const MonthlyFee = require("../models/MonthlyFee.model");

async function updateIndexes() {
  try {
    // Conectar a la base de datos
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log("✅ Conectado a MongoDB");

    // Eliminar índices antiguos
    console.log("🔄 Eliminando índices antiguos...");
    try {
      // Intentar eliminar el índice único antiguo de userId
      await MonthlyFee.collection.dropIndex("communityId_1_userId_1_month_1");
      console.log("✅ Índice antiguo (communityId_userId_month) eliminado");
    } catch (error) {
      console.log("ℹ️ El índice antiguo no existe o ya fue eliminado");
    }

    // Sincronizar índices con el modelo actual
    console.log("🔄 Recreando índices según el modelo actual...");
    await MonthlyFee.syncIndexes();
    console.log("✅ Índices actualizados correctamente");

    // Mostrar los índices actuales
    const indexes = await MonthlyFee.collection.getIndexes();
    console.log("\n📋 Índices actuales en la colección monthlyFees:");
    Object.keys(indexes).forEach(indexName => {
      console.log(`  - ${indexName}:`, indexes[indexName].key);
    });

    // Verificar si hay mensualidades duplicadas por casa
    console.log("\n🔍 Verificando posibles duplicados por casa...");
    const duplicates = await MonthlyFee.aggregate([
      {
        $group: {
          _id: {
            houseId: "$houseId",
            month: "$month",
            communityId: "$communityId"
          },
          count: { $sum: 1 },
          ids: { $push: "$_id" }
        }
      },
      {
        $match: {
          count: { $gt: 1 }
        }
      }
    ]);

    if (duplicates.length > 0) {
      console.log(`⚠️ Se encontraron ${duplicates.length} grupos de duplicados:`);
      duplicates.forEach(dup => {
        console.log(`  Casa: ${dup._id.houseId}, Mes: ${dup._id.month}, Cantidad: ${dup.count}`);
      });
      console.log("\nNecesitas resolver estos duplicados antes de que el índice único funcione correctamente.");
    } else {
      console.log("✅ No se encontraron duplicados por casa");
    }

    console.log("\n✅ Proceso completado exitosamente");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  }
}

updateIndexes();