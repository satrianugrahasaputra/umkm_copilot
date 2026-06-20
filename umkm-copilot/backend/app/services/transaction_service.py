import datetime
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from typing import Dict, Any, List, Optional

from app.models.models import Transaction, Product, AIExtraction, AISession, AIMessage
from app.schemas.schemas import TransactionCreate, ExtractedTransactionItem
from app.services.ai_service import AIService

class TransactionService:
    @staticmethod
    def get_user_transactions(db: Session, user_id: str, limit: int = 100) -> List[Transaction]:
        return db.query(Transaction).filter(
            Transaction.user_id == user_id
        ).order_by(Transaction.created_at.desc()).limit(limit).all()

    @classmethod
    def create_transaction(cls, db: Session, user_id: str, data: TransactionCreate) -> Transaction:
        # Create transaction record
        tx = Transaction(
            user_id=user_id,
            transaction_type=data.type,
            total=data.amount,
            qty=1,
            unit_price=data.amount,
            input_type="manual"
        )
        db.add(tx)
        db.commit()
        db.refresh(tx)
        return tx

    @classmethod
    def parse_and_stage_transaction(cls, db: Session, user_id: str, text: str, session_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Parses raw text using AI, stores the message in the DB, and stages a pending extraction.
        """
        # Ensure a session exists
        if not session_id:
            session = AISession(user_id=user_id, session_title="Percakapan Baru")
            db.add(session)
            db.commit()
            db.refresh(session)
            session_id = session.id
        else:
            session = db.query(AISession).filter(AISession.id == session_id, AISession.user_id == user_id).first()
            if not session:
                raise HTTPException(status_code=404, detail="Sesi percakapan tidak ditemukan")
                
        # 1. Save user's chat message
        user_message = AIMessage(
            session_id=session_id,
            role="user",
            message=text
        )
        db.add(user_message)
        db.commit()
        db.refresh(user_message)

        # 2. Extract transaction parameters using AI
        extracted_data = AIService.parse_transaction(text)

        # Look up product to suggest a real unit price if user did not specify amount
        prod_name = extracted_data.get("product", "barang")
        product = db.query(Product).filter(
            Product.user_id == user_id, 
            Product.name.ilike(prod_name)
        ).first()

        qty = extracted_data.get("qty", 1)
        if not extracted_data.get("amount") or extracted_data["amount"] == 0:
            if product:
                extracted_data["amount"] = float(product.price) * qty
            else:
                extracted_data["amount"] = 15000.0 * qty

        # 3. Save assistant's pending extraction message
        assistant_content = f"Konfirmasi Transaksi: {extracted_data['type'].upper()} - {extracted_data['product']} sejumlah {extracted_data['qty']} dengan total Rp {extracted_data['amount']:,.0f}."
        assistant_message = AIMessage(
            session_id=session_id,
            role="assistant",
            message=assistant_content
        )
        db.add(assistant_message)
        db.commit()
        db.refresh(assistant_message)

        # 4. Save the extraction details
        extraction = AIExtraction(
            user_id=user_id,
            raw_input=text,
            parsed_json=extracted_data,
            status="pending_confirmation"
        )
        db.add(extraction)
        db.commit()
        db.refresh(extraction)

        return {
            "success": True,
            "raw_text": text,
            "extracted_data": extracted_data,
            "message_id": assistant_message.id,
            "session_id": session_id,
            "extraction_id": extraction.id
        }

    @classmethod
    def confirm_extraction(cls, db: Session, user_id: str, extraction_id: str, confirmed_data: ExtractedTransactionItem) -> Transaction:
        """
        Confirms a pending extraction, creates the actual transaction record, updates/creates the product stock, and updates extraction status.
        """
        extraction = db.query(AIExtraction).filter(AIExtraction.id == extraction_id, AIExtraction.user_id == user_id).first()
        if not extraction:
            raise HTTPException(status_code=404, detail="Data ekstraksi tidak ditemukan")
            
        if extraction.status == "confirmed":
            raise HTTPException(status_code=400, detail="Transaksi ini sudah pernah dikonfirmasi sebelumnya")

        # Find or create product
        product_name = confirmed_data.product.strip()
        product = db.query(Product).filter(
            Product.user_id == user_id, 
            Product.name.ilike(product_name)
        ).first()

        amount = confirmed_data.amount if confirmed_data.amount else 0.0

        if not product:
            unit_price = amount / confirmed_data.qty if confirmed_data.qty > 0 else 0
            product = Product(
                user_id=user_id,
                name=product_name,
                price=unit_price if unit_price > 0 else 15000.0,
                stock=0,
                category="Kuliner"
            )
            db.add(product)
            db.commit()
            db.refresh(product)

        # Adjust product stock
        is_income = confirmed_data.type in ["income", "pemasukan"]
        if is_income:
            product.stock = max(0, product.stock - confirmed_data.qty)
        else:
            product.stock = product.stock + confirmed_data.qty

        db.add(product)

        # Create Transaction
        tx = Transaction(
            user_id=user_id,
            product_id=product.id,
            qty=confirmed_data.qty,
            unit_price=amount / confirmed_data.qty if confirmed_data.qty > 0 else amount,
            total=amount,
            transaction_type="income" if is_income else "expense",
            input_type="chat"
        )
        db.add(tx)
        
        # Update extraction
        extraction.status = "confirmed"
        db.add(extraction)
        db.commit()
        db.refresh(tx)

        return tx
