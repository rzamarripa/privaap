require("dotenv").config();
const mongoose = require("mongoose");
const MonthlyFee = require("../models/MonthlyFee.model");
const Payment = require("../models/Payment.model");
const House = require("../models/House.model");
const Community = require("../models/Community.model");

async function fixIncorrectMonthlyFees() {
  try {
    // Conectar a la base de datos
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log("✅ Conectado a MongoDB");

    console.log("🔍 Buscando mensualidades con montos incorrectos...");
    
    // Obtener todas las mensualidades
    const monthlyFees = await MonthlyFee.find({}).populate('houseId');
    
    console.log(`📊 Total de mensualidades encontradas: ${monthlyFees.length}`);
    
    let incorrectFees = [];
    
    for (const fee of monthlyFees) {
      if (!fee.houseId) {
        console.log(`⚠️  Mensualidad sin casa asociada: ${fee._id}`);
        continue;
      }
      
      // Obtener la comunidad para verificar el monto correcto
      const house = await House.findById(fee.houseId).populate('communityId');
      if (!house) {
        console.log(`⚠️  Casa no encontrada para mensualidad: ${fee._id}`);
        continue;
      }
      
      // Obtener el monto correcto (de la comunidad o de la casa)
      const correctAmount = house.communityId?.monthlyFee || house.monthlyFee || 1000;
      
      // Verificar si el monto es incorrecto
      if (fee.amount < correctAmount && fee.status === 'pagado' && fee.amountPaid === fee.amount) {
        incorrectFees.push({
          feeId: fee._id,
          houseNumber: house.houseNumber,
          currentAmount: fee.amount,
          correctAmount: correctAmount,
          amountPaid: fee.amountPaid,
          month: fee.month,
          status: fee.status
        });
      }
    }
    
    console.log(`\n🎯 Mensualidades incorrectas encontradas: ${incorrectFees.length}`);
    
    if (incorrectFees.length === 0) {
      console.log("✅ No se encontraron mensualidades con montos incorrectos");
      process.exit(0);
    }
    
    // Mostrar resumen de mensualidades incorrectas
    console.log("\n📋 Mensualidades que serán corregidas:");
    incorrectFees.forEach((fee, index) => {
      console.log(`${index + 1}. Casa ${fee.houseNumber} - ${fee.month}`);
      console.log(`   Monto actual: $${fee.currentAmount} → Monto correcto: $${fee.correctAmount}`);
      console.log(`   Pagado: $${fee.amountPaid} - Estado: ${fee.status}\n`);
    });
    
    // Preguntar confirmación (en un entorno real, podrías usar readline)
    console.log("🚨 ATENCIÓN: Esta operación eliminará las mensualidades incorrectas.");
    console.log("   Después deberás recrearlas con el monto correcto usando la app.");
    
    // En lugar de pedir confirmación interactiva, vamos a proceder automáticamente
    // pero solo si hay menos de 10 registros para evitar eliminar mucho por accidente
    if (incorrectFees.length > 10) {
      console.log("❌ Demasiados registros para procesar automáticamente. Revisa manualmente.");
      process.exit(1);
    }
    
    console.log("\n🔄 Procediendo a eliminar mensualidades incorrectas...");
    
    let deletedCount = 0;
    let paymentCount = 0;
    
    for (const incorrectFee of incorrectFees) {
      try {
        // Primero eliminar cualquier pago asociado
        const payments = await Payment.find({ monthlyFeeId: incorrectFee.feeId });
        if (payments.length > 0) {
          await Payment.deleteMany({ monthlyFeeId: incorrectFee.feeId });
          paymentCount += payments.length;
          console.log(`   Eliminados ${payments.length} pagos de mensualidad ${incorrectFee.feeId}`);
        }
        
        // Eliminar la mensualidad
        await MonthlyFee.findByIdAndDelete(incorrectFee.feeId);
        deletedCount++;
        console.log(`✅ Eliminada mensualidad incorrecta: Casa ${incorrectFee.houseNumber} - ${incorrectFee.month}`);
        
      } catch (error) {
        console.error(`❌ Error eliminando mensualidad ${incorrectFee.feeId}:`, error.message);
      }
    }
    
    console.log(`\n📊 Resumen de la operación:`);
    console.log(`   Mensualidades eliminadas: ${deletedCount}`);
    console.log(`   Pagos eliminados: ${paymentCount}`);
    
    console.log("\n✅ Proceso completado.");
    console.log("\n🎯 PRÓXIMOS PASOS:");
    console.log("   1. Reinicia la aplicación Flutter");
    console.log("   2. Crea nuevamente las mensualidades con el monto correcto");
    console.log("   3. Los pagos parciales ahora funcionarán correctamente");
    
    process.exit(0);
    
  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  }
}

fixIncorrectMonthlyFees();