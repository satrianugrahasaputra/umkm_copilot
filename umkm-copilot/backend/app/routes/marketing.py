from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.schemas.schemas import MarketingGenerateRequest, MarketingResponse
from app.models.models import User
from app.services.auth_service import get_current_user
from app.services.marketing_service import MarketingService

router = APIRouter(prefix="/marketing", tags=["Marketing Generator"])

@router.post("/generate", response_model=MarketingResponse, status_code=status.HTTP_201_CREATED)
def generate_content(
    request: MarketingGenerateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        return MarketingService.generate_and_save(db, current_user.id, request)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal membuat konten promosi: {str(e)}"
        )

@router.get("", response_model=List[MarketingResponse])
def get_past_contents(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return MarketingService.get_user_contents(db, current_user.id)
