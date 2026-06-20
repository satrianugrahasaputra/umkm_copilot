import datetime
import uuid
from sqlalchemy import Column, String, Boolean, DateTime, Numeric, Integer, Text, ForeignKey, JSON
from sqlalchemy.orm import relationship
from app.database import Base

def generate_uuid():
    return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    full_name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    business_name = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    @property
    def fullname(self):
        return self.full_name

    # Relationships
    products = relationship("Product", back_populates="user", cascade="all, delete-orphan")
    transactions = relationship("Transaction", back_populates="user", cascade="all, delete-orphan")
    ai_sessions = relationship("AISession", back_populates="user", cascade="all, delete-orphan")
    ai_extractions = relationship("AIExtraction", back_populates="user", cascade="all, delete-orphan")
    marketing_contents = relationship("MarketingContent", back_populates="user", cascade="all, delete-orphan")
    insights = relationship("Insight", back_populates="user", cascade="all, delete-orphan")
    reports = relationship("Report", back_populates="user", cascade="all, delete-orphan")
    sales_summaries = relationship("SalesSummary", back_populates="user", cascade="all, delete-orphan")


class Product(Base):
    __tablename__ = "products"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String, index=True, nullable=False)
    description = Column(String, nullable=True)
    category = Column(String, nullable=True)
    price = Column(Numeric(10, 2), nullable=False)
    stock = Column(Integer, default=0)
    image_url = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="products")
    transactions = relationship("Transaction", back_populates="product", cascade="all, delete-orphan")
    marketing_contents = relationship("MarketingContent", back_populates="product", cascade="all, delete-orphan")


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    product_id = Column(String(36), ForeignKey("products.id", ondelete="SET NULL"), nullable=True)
    qty = Column(Integer, default=1)
    unit_price = Column(Numeric(10, 2), nullable=False)
    total = Column(Numeric(10, 2), nullable=False)
    transaction_type = Column(String, nullable=False)  # 'income' or 'expense'
    input_type = Column(String, default="chat")  # 'chat' or 'manual' or 'voice'
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    update_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    @property
    def type(self):
        return self.transaction_type

    @property
    def amount(self):
        return float(self.total)

    @property
    def timestamp(self):
        return self.created_at

    @property
    def status(self):
        return "completed"

    # Relationships
    user = relationship("User", back_populates="transactions")
    product = relationship("Product", back_populates="transactions")


class AISession(Base):
    __tablename__ = "ai_sessions"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    session_title = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    update_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    @property
    def title(self):
        return self.session_title

    # Relationships
    user = relationship("User", back_populates="ai_sessions")
    messages = relationship("AIMessage", back_populates="session", cascade="all, delete-orphan")


class AIMessage(Base):
    __tablename__ = "ai_messages"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    session_id = Column(String(36), ForeignKey("ai_sessions.id", ondelete="CASCADE"), nullable=False)
    role = Column(String, nullable=False)  # 'user' / 'assistant'
    message = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    @property
    def sender(self):
        return self.role

    @property
    def content(self):
        return self.message

    @property
    def timestamp(self):
        return self.created_at

    # Relationships
    session = relationship("AISession", back_populates="messages")


class AIExtraction(Base):
    __tablename__ = "ai_extractions"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    raw_input = Column(Text, nullable=False)
    parsed_json = Column(JSON, nullable=False)
    status = Column(String, default="pending_confirmation")  # 'confirmed', 'failed', 'pending_confirmation'
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    @property
    def raw_text(self):
        return self.raw_input

    @property
    def extracted_json(self):
        return self.parsed_json

    # Relationships
    user = relationship("User", back_populates="ai_extractions")


class MarketingContent(Base):
    __tablename__ = "marketing_contents"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    product_id = Column(String(36), ForeignKey("products.id", ondelete="SET NULL"), nullable=True)
    platform = Column(String, nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    @property
    def topic(self):
        return "Promosi Produk"

    @property
    def generated_content(self):
        return self.content

    # Relationships
    user = relationship("User", back_populates="marketing_contents")
    product = relationship("Product", back_populates="marketing_contents")


class Insight(Base):
    __tablename__ = "insights"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String, nullable=False)
    summary = Column(Text, nullable=False)
    recommendation = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    @property
    def category(self):
        return self.title

    @property
    def content(self):
        return self.summary

    # Relationships
    user = relationship("User", back_populates="insights")


class Report(Base):
    __tablename__ = "reports"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    period = Column(String, nullable=False)  # 'daily', 'weekly', 'monthly'
    summary = Column(Text, nullable=True)
    generated_by = Column(String, default="system")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    @property
    def type(self):
        return self.period

    @property
    def ai_summary(self):
        return self.summary

    @property
    def start_date(self):
        return self.created_at.date()

    @property
    def end_date(self):
        return self.created_at.date()

    @property
    def total_revenue(self):
        return 0.0

    @property
    def total_transactions(self):
        return 0

    # Relationships
    user = relationship("User", back_populates="reports")


class SalesSummary(Base):
    __tablename__ = "sales_summary"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    period_start = Column(DateTime, nullable=False)
    period_end = Column(DateTime, nullable=False)
    total_revenue = Column(Numeric(10, 2), default=0.0)
    total_transactions = Column(Integer, default=0)
    best_product = Column(String, nullable=True)
    growth_percent = Column(Numeric(5, 2), default=0.0)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="sales_summaries")
