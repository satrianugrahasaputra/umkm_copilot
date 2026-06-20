from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# Load env variables
load_dotenv()

# Import Database & Models to trigger auto-creation
from app.database import engine, Base
from app.models import models

# Create database tables if they don't exist
Base.metadata.create_all(bind=engine)

# Import routes
from app.routes import auth, products, chat, marketing, reports, dashboard

app = FastAPI(
    title="UMKM Copilot Indonesia API",
    description="Sistem AI Generatif untuk membantu UMKM Indonesia mencatat transaksi, menganalisis bisnis, dan membuat konten pemasaran.",
    version="1.0.0"
)

# CORS middleware config (Essential for Flutter Web or local emulators)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Root Endpoint
@app.get("/")
def read_root():
    return {
        "app": "UMKM Copilot Indonesia API",
        "status": "healthy",
        "version": "1.0.0",
        "documentation": "/docs"
    }

# Register Routers
app.include_router(auth.router, prefix="/api")
app.include_router(products.router, prefix="/api")
app.include_router(chat.router, prefix="/api")
app.include_router(marketing.router, prefix="/api")
app.include_router(reports.router, prefix="/api")
app.include_router(dashboard.router, prefix="/api")
