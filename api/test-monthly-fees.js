const axios = require("axios");

// Configuración
const BASE_URL = "http://localhost:3001/api";
const TEST_USER = {
  email: "admin@test.com",
  password: "password123",
};

let authToken = "";

// Función para hacer login y obtener token
async function login() {
  try {
    console.log("🔐 Iniciando sesión...");
    const response = await axios.post(`${BASE_URL}/auth/login`, TEST_USER);

    if (response.data.success) {
      authToken = response.data.token;
      console.log("✅ Login exitoso");
      return true;
    } else {
      console.log("❌ Error en login:", response.data.error);
      return false;
    }
  } catch (error) {
    console.log("❌ Error de conexión:", error.message);
    return false;
  }
}

// Función para probar las rutas de mensualidades
async function testMonthlyFees() {
  if (!authToken) {
    console.log("❌ No hay token de autenticación");
    return;
  }

  const headers = {
    Authorization: `Bearer ${authToken}`,
    "Content-Type": "application/json",
  };

  try {
    console.log("\n🧪 Probando rutas de mensualidades...\n");

    // 1. Obtener todas las mensualidades
    console.log("1️⃣ Probando GET /monthly-fees...");
    try {
      const response = await axios.get(`${BASE_URL}/monthly-fees`, { headers });
      console.log("✅ GET /monthly-fees exitoso");
      console.log(
        `   Total mensualidades: ${
          response.data.data?.monthlyFees?.length || 0
        }`
      );
    } catch (error) {
      console.log(
        "❌ GET /monthly-fees falló:",
        error.response?.data?.error || error.message
      );
    }

    // 2. Obtener mensualidades del usuario
    console.log("\n2️⃣ Probando GET /monthly-fees/user...");
    try {
      const response = await axios.get(`${BASE_URL}/monthly-fees/user`, {
        headers,
      });
      console.log("✅ GET /monthly-fees/user exitoso");
      console.log(
        `   Mensualidades del usuario: ${response.data.data?.length || 0}`
      );
    } catch (error) {
      console.log(
        "❌ GET /monthly-fees/user falló:",
        error.response?.data?.error || error.message
      );
    }

    // 3. Obtener resumen financiero
    console.log("\n3️⃣ Probando GET /monthly-fees/summary...");
    try {
      const response = await axios.get(`${BASE_URL}/monthly-fees/summary`, {
        headers,
      });
      console.log("✅ GET /monthly-fees/summary exitoso");
      console.log(`   Resumen: ${JSON.stringify(response.data.data)}`);
    } catch (error) {
      console.log(
        "❌ GET /monthly-fees/summary falló:",
        error.response?.data?.error || error.message
      );
    }

    // 4. Probar filtros
    console.log("\n4️⃣ Probando filtros en GET /monthly-fees...");
    try {
      const response = await axios.get(
        `${BASE_URL}/monthly-fees?status=pendiente&limit=5`,
        { headers }
      );
      console.log("✅ Filtros funcionando");
      console.log(
        `   Mensualidades pendientes: ${
          response.data.data?.monthlyFees?.length || 0
        }`
      );
    } catch (error) {
      console.log(
        "❌ Filtros fallaron:",
        error.response?.data?.error || error.message
      );
    }

    console.log("\n🎉 Pruebas completadas!");
  } catch (error) {
    console.log("❌ Error general:", error.message);
  }
}

// Función principal
async function main() {
  console.log("🚀 Iniciando pruebas del módulo de mensualidades...\n");

  const loginSuccess = await login();
  if (loginSuccess) {
    await testMonthlyFees();
  } else {
    console.log("❌ No se pudo continuar sin autenticación");
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  main().catch(console.error);
}

module.exports = { login, testMonthlyFees };
