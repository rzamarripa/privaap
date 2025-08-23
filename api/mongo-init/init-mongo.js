// Script de inicialización para MongoDB
// Se ejecuta automáticamente cuando se crea el contenedor

// Crear la base de datos privaap
db = db.getSiblingDB("privaap");

// Crear usuario para la aplicación
db.createUser({
  user: "privaap_user",
  pwd: "privaap_user_password",
  roles: [
    {
      role: "readWrite",
      db: "privaap",
    },
  ],
});

// Crear colecciones iniciales
db.createCollection("users");
db.createCollection("communities");
db.createCollection("houses");
db.createCollection("monthlyfees");
db.createCollection("expenses");
db.createCollection("payments");
db.createCollection("surveys");
db.createCollection("blogposts");
db.createCollection("proposals");
db.createCollection("supporttickets");

// Crear índices básicos
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ phone: 1 });
db.communities.createIndex({ name: 1 });
db.houses.createIndex({ communityId: 1 });
db.houses.createIndex({ unitNumber: 1 });
db.monthlyfees.createIndex({ communityId: 1, month: 1, year: 1 });
db.expenses.createIndex({ communityId: 1, date: 1 });
db.payments.createIndex({ monthlyFeeId: 1 });
db.surveys.createIndex({ communityId: 1, status: 1 });

print("Base de datos privaap inicializada correctamente");
print("Usuario privaap_user creado con permisos de lectura/escritura");
