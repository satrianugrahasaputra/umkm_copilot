from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Dict, Any
import datetime

from app.models.models import Transaction, Product, Insight
from app.schemas.schemas import DashboardData
from app.services.insight_service import InsightService

class DashboardService:
    @classmethod
    def get_dashboard_data(cls, db: Session, user_id: int) -> Dict[str, Any]:
        # Calculate revenue (income)
        revenue_query = db.query(func.sum(Transaction.amount)).filter(
            Transaction.user_id == user_id,
            Transaction.type == "income"
        ).scalar()
        revenue = float(revenue_query) if revenue_query else 0.0

        # Calculate expense
        expense_query = db.query(func.sum(Transaction.amount)).filter(
            Transaction.user_id == user_id,
            Transaction.type == "expense"
        ).scalar()
        expense = float(expense_query) if expense_query else 0.0

        # Net Profit
        net_profit = revenue - expense

        # Transaction Count
        transaction_count = db.query(Transaction).filter(
            Transaction.user_id == user_id
        ).count()

        # Recent Transactions (last 5)
        recent_transactions = db.query(Transaction).filter(
            Transaction.user_id == user_id
        ).order_by(Transaction.timestamp.desc()).limit(5).all()

        # Top Product Calculation (mocking or real logic if connected to transactions)
        # For simplicity, we can pick the product with the lowest stock or highest price as top product
        # Or we can query existing products. Let's query products and pick the one with most stock or a mock top product.
        top_product_db = db.query(Product).filter(Product.user_id == user_id).order_by(Product.price.desc()).first()
        top_product = None
        if top_product_db:
            top_product = {
                "id": top_product_db.id,
                "name": top_product_db.name,
                "price": top_product_db.price,
                "sales_count": 25  # Mock sales count for dashboard
            }

        # Latest AI Insight
        insight = InsightService.get_latest_insight(db, user_id)
        # If no insight exists, generate one on the fly (or use default)
        if not insight:
            try:
                insight = InsightService.generate_and_save_insight(db, user_id)
            except Exception:
                insight = None
        
        ai_insight_text = insight.content if insight else "Mulai catat transaksi penjualan Anda untuk mendapatkan insight bisnis bertenaga AI di sini."

        return {
            "revenue": revenue,
            "expense": expense,
            "net_profit": net_profit,
            "transaction_count": transaction_count,
            "top_product": top_product,
            "recent_transactions": recent_transactions,
            "ai_insight": ai_insight_text
        }
