from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
import datetime

from app.models.models import Insight, Transaction, Product
from app.services.ai_service import AIService

class InsightService:
    @classmethod
    def generate_and_save_insight(cls, db: Session, user_id: int) -> Insight:
        # 1. Fetch recent transactions for summary
        recent_txs = db.query(Transaction).filter(
            Transaction.user_id == user_id
        ).order_by(Transaction.timestamp.desc()).limit(15).all()
        
        tx_lines = []
        for tx in recent_txs:
            tx_lines.append(f"- {tx.timestamp.strftime('%Y-%m-%d')}: {tx.type.upper()} Rp {tx.amount:,.0f} ({tx.description or ''})")
        tx_summary = "\n".join(tx_lines) if tx_lines else "Belum ada transaksi dicatat."
        
        # 2. Fetch products for listing
        products = db.query(Product).filter(Product.user_id == user_id).limit(10).all()
        prod_lines = []
        for p in products:
            prod_lines.append(f"- {p.name}: Harga Rp {p.price:,.0f}, Stok {p.stock} {p.unit}")
        prod_list = "\n".join(prod_lines) if prod_lines else "Belum ada produk terdaftar."

        # 3. Call AI
        ai_insight_text = AIService.generate_insight(tx_summary, prod_list)
        
        # 4. Save
        new_insight = Insight(
            user_id=user_id,
            category="sales",
            content=ai_insight_text,
            recommendation="Silakan ikuti poin rekomendasi di atas untuk hasil maksimal."
        )
        db.add(new_insight)
        db.commit()
        db.refresh(new_insight)
        return new_insight

    @staticmethod
    def get_latest_insight(db: Session, user_id: int) -> Optional[Insight]:
        return db.query(Insight).filter(
            Insight.user_id == user_id
        ).order_by(Insight.created_at.desc()).first()
