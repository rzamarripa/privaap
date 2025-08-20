require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const rateLimit = require("express-rate-limit");

// Import routes
const authRoutes = require("./routes/auth.routes");
const userRoutes = require("./routes/user.routes");
const expenseRoutes = require("./routes/expense.routes");
const surveyRoutes = require("./routes/survey.routes");
const blogRoutes = require("./routes/blog.routes");
const proposalRoutes = require("./routes/proposal.routes");
const communityRoutes = require("./routes/community.routes");
const supportRoutes = require("./routes/support.routes");
const monthlyFeeRoutes = require("./routes/monthly-fee.routes");
const houseRoutes = require("./routes/house.routes");
const paymentRoutes = require("./routes/payment.routes");

// Import error handler
const errorHandler = require("./middlewares/errorHandler");

const app = express();

// Security middleware
app.use(helmet());

// CORS configuration - Permitir múltiples orígenes para desarrollo
const allowedOrigins = [
  "http://localhost:3001",
  "http://localhost:3000",
  "http://127.0.0.1:3001",
  "http://192.168.100.136:3001",
  // Para Flutter/Mobile apps
  "capacitor://localhost",
  "ionic://localhost",
  "http://localhost",
  "http://127.0.0.1",
  "http://192.168.100.136",
];

app.use(
  cors({
    origin: function (origin, callback) {
      // Permitir requests sin origin (mobile apps, curl, etc.)
      if (!origin) return callback(null, true);

      if (allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        // En desarrollo, permitir todos los orígenes locales
        if (
          process.env.NODE_ENV === "development" ||
          origin.includes("localhost") ||
          origin.includes("127.0.0.1") ||
          origin.includes("192.168.")
        ) {
          callback(null, true);
        } else {
          callback(new Error("Not allowed by CORS"));
        }
      }
    },
    credentials: true,
  })
);

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 500, // limit each IP to 500 requests per windowMs (increased from 100)
  message: "Demasiadas solicitudes desde esta IP, por favor intenta de nuevo más tarde.",
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});
app.use("/api/", limiter);

// Logging
if (process.env.NODE_ENV === "development") {
  app.use(morgan("dev"));
}

// Body parser with increased limits
app.use(express.json({ limit: '50mb' })); // Increased from default 100kb
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Static files
app.use("/uploads", express.static("uploads"));

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/expenses", expenseRoutes);
app.use("/api/surveys", surveyRoutes);
app.use("/api/blog", blogRoutes);
app.use("/api/proposals", proposalRoutes);
app.use("/api/communities", communityRoutes);
app.use("/api/support", supportRoutes);
app.use("/api/monthly-fees", monthlyFeeRoutes);
app.use("/api/houses", houseRoutes);
app.use("/api/payments", paymentRoutes);

// Health check endpoint
app.get("/api/health", (req, res) => {
  res.json({
    status: "OK",
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: "Route not found" });
});

// Error handling middleware
app.use(errorHandler);

// Database connection
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log("MongoDB connected successfully");
  } catch (error) {
    console.error("MongoDB connection error:", error);
    process.exit(1);
  }
};

// Start server
const PORT = process.env.PORT || 3004;

const startServer = async () => {
  await connectDB();

  app.listen(PORT, () => {
    console.log(
      `Server running on port ${PORT} in ${process.env.NODE_ENV} mode`
    );
  });
};

// Handle unhandled promise rejections
process.on("unhandledRejection", (err) => {
  console.error("UNHANDLED REJECTION! 💥 Shutting down...");
  console.error(err.name, err.message);
  process.exit(1);
});

startServer();

module.exports = app;
