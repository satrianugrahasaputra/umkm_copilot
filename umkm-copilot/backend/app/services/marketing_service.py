from sqlalchemy.orm import Session
from typing import List
from app.models.models import MarketingContent
from app.schemas.schemas import MarketingGenerateRequest
from app.services.ai_service import AIService

class MarketingService:
    @staticmethod
    def generate_and_save(db: Session, user_id: int, request: MarketingGenerateRequest) -> MarketingContent:
        generated_text = AIService.generate_marketing(
            platform=request.platform,
            topic=request.topic,
            product_name=request.product_name,
            tone=request.tone
        )
        
        db_content = MarketingContent(
            user_id=user_id,
            platform=request.platform,
            topic=request.topic,
            generated_content=generated_text
        )
        db.add(db_content)
        db.commit()
        db.refresh(db_content)
        return db_content

    @staticmethod
    def get_user_contents(db: Session, user_id: int, limit: int = 50) -> List[MarketingContent]:
        return db.query(MarketingContent).filter(
            MarketingContent.user_id == user_id
        ).order_by(MarketingContent.created_at.desc()).limit(limit).all()
