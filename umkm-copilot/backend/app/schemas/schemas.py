from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, date

# --- AUTH ---
class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6)
    fullname: str
    business_name: Optional[str] = None
    phone_number: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class UserResponse(BaseModel):
    id: str
    email: EmailStr
    fullname: str
    business_name: Optional[str]
    phone_number: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

# --- PRODUCT ---
class ProductCreate(BaseModel):
    name: str
    description: Optional[str] = None
    price: float = Field(..., gt=0)
    stock: int = Field(0, ge=0)
    unit: str = "pcs"

class ProductResponse(BaseModel):
    id: str
    user_id: str
    name: str
    description: Optional[str]
    price: float
    stock: int
    unit: str
    created_at: datetime

    class Config:
        from_attributes = True

# --- TRANSACTION ---
class TransactionCreate(BaseModel):
    type: str = Field(..., pattern="^(income|expense|pemasukan|pengeluaran)$")
    amount: float = Field(..., gt=0)
    description: Optional[str] = None
    status: str = "completed"
    timestamp: Optional[datetime] = None

class TransactionResponse(BaseModel):
    id: str
    user_id: str
    type: str
    amount: float
    description: Optional[str]
    timestamp: datetime
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

# --- AI PARSING & EXTRACTION ---
class TransactionParseRequest(BaseModel):
    text: str
    session_id: Optional[str] = None

class ExtractedTransactionItem(BaseModel):
    product: str
    qty: int
    type: str = "income"
    amount: Optional[float] = None
    description: Optional[str] = None

class TransactionParseResponse(BaseModel):
    success: bool
    raw_text: str
    extracted_data: ExtractedTransactionItem
    message_id: str
    session_id: str
    extraction_id: str

class TransactionConfirmRequest(BaseModel):
    extraction_id: str
    confirmed_data: ExtractedTransactionItem

# --- CHAT ---
class ChatMessageResponse(BaseModel):
    id: str
    sender: str
    content: str
    timestamp: datetime

    class Config:
        from_attributes = True

class ChatSessionResponse(BaseModel):
    id: str
    title: str
    created_at: datetime
    messages: List[ChatMessageResponse] = []

    class Config:
        from_attributes = True

# --- MARKETING ---
class MarketingGenerateRequest(BaseModel):
    platform: str = Field(..., pattern="^(instagram|whatsapp|marketplace)$")
    topic: str
    product_name: Optional[str] = None
    tone: Optional[str] = "friendly"

class MarketingResponse(BaseModel):
    id: str
    platform: str
    topic: str
    generated_content: str
    created_at: datetime

    class Config:
        from_attributes = True

# --- INSIGHTS ---
class InsightResponse(BaseModel):
    id: str
    category: str
    content: str
    recommendation: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

# --- REPORTS & DASHBOARD ---
class ReportResponse(BaseModel):
    id: str
    type: str
    start_date: date
    end_date: date
    total_revenue: float
    total_transactions: int
    ai_summary: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class DashboardData(BaseModel):
    revenue: float
    expense: float
    net_profit: float
    transaction_count: int
    top_product: Optional[Dict[str, Any]] = None
    recent_transactions: List[TransactionResponse]
    ai_insight: Optional[str]
