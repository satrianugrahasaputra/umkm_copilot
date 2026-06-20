from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.schemas.schemas import (
    TransactionParseRequest, TransactionParseResponse, 
    TransactionConfirmRequest, TransactionResponse,
    InsightResponse, ChatSessionResponse
)
from app.models.models import User, AISession, AIExtraction
from app.services.auth_service import get_current_user
from app.services.transaction_service import TransactionService
from app.services.insight_service import InsightService

router = APIRouter(prefix="/chat", tags=["AI Chat & Extraction"])

@router.post("/parse-transaction", response_model=TransactionParseResponse)
def parse_transaction(
    request: TransactionParseRequest, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    try:
        result = TransactionService.parse_and_stage_transaction(
            db=db, 
            user_id=current_user.id, 
            text=request.text, 
            session_id=request.session_id
        )
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal memproses teks transaksi: {str(e)}"
        )

@router.post("/confirm-transaction", response_model=TransactionResponse)
def confirm_transaction(
    request: TransactionConfirmRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return TransactionService.confirm_extraction(
        db=db,
        user_id=current_user.id,
        extraction_id=request.extraction_id,
        confirmed_data=request.confirmed_data
    )

@router.post("/insight", response_model=InsightResponse)
def generate_insight(
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    try:
        return InsightService.generate_and_save_insight(db, current_user.id)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal membuat rekomendasi bisnis: {str(e)}"
        )

@router.get("/sessions", response_model=List[ChatSessionResponse])
def get_sessions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return db.query(AISession).filter(AISession.user_id == current_user.id).order_by(AISession.updated_at.desc()).all()

@router.get("/sessions/{session_id}", response_model=ChatSessionResponse)
def get_session(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    session = db.query(AISession).filter(
        AISession.id == session_id,
        AISession.user_id == current_user.id
    ).first()
    if not session:
        raise HTTPException(status_code=404, detail="Sesi percakapan tidak ditemukan")
    return session
