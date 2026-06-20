from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
import datetime

from app.database import get_db
from app.schemas.schemas import ReportResponse
from app.models.models import User, Report, Transaction
from app.services.auth_service import get_current_user
from app.services.ai_service import AIService

router = APIRouter(prefix="/reports", tags=["Reports"])

@router.get("", response_model=List[ReportResponse])
def get_reports(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return db.query(Report).filter(Report.user_id == current_user.id).order_by(Report.created_at.desc()).all()

@router.post("/generate", response_model=ReportResponse, status_code=status.HTTP_201_CREATED)
def generate_report(
    type: str, # 'daily', 'weekly', 'monthly'
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if type not in ["daily", "weekly", "monthly"]:
        raise HTTPException(status_code=400, detail="Tipe laporan harus 'daily', 'weekly', atau 'monthly'")
        
    end_date = datetime.date.today()
    if type == "daily":
        start_date = end_date
    elif type == "weekly":
        start_date = end_date - datetime.timedelta(days=7)
    else:
        start_date = end_date - datetime.timedelta(days=30)
        
    # Calculate stats
    start_dt = datetime.datetime.combine(start_date, datetime.time.min)
    end_dt = datetime.datetime.combine(end_date, datetime.time.max)
    
    txs = db.query(Transaction).filter(
        Transaction.user_id == current_user.id,
        Transaction.timestamp >= start_dt,
        Transaction.timestamp <= end_dt
    ).all()
    
    total_rev = sum(t.amount for t in txs if t.type == "income")
    total_exp = sum(t.amount for t in txs if t.type == "expense")
    total_count = len(txs)
    
    # Generate simple summary using AI or local rules
    ai_summary = f"Laporan {type} untuk periode {start_date} s/d {end_date}. "
    if total_count > 0:
        summary_prompt = (
            f"Tolong buat ringkasan bisnis super singkat satu paragraf dalam bahasa Indonesia "
            f"untuk laporan {type} dengan total pemasukan Rp {total_rev:,.0f}, "
            f"total pengeluaran Rp {total_exp:,.0f}, dan total transaksi sebanyak {total_count}."
        )
        try:
            # We can use Gemini if available, otherwise fallback
            if AIService.GEMINI_API_KEY:
                import google.generativeai as genai
                model = genai.GenerativeModel("gemini-1.5-flash")
                response = model.generate_content(summary_prompt)
                ai_summary += response.text.strip()
            else:
                ai_summary += f"Bisnis Anda memperoleh keuntungan bersih sebesar Rp {total_rev - total_exp:,.0f}. Kinerja stabil."
        except Exception:
            ai_summary += f"Bisnis Anda memperoleh keuntungan bersih sebesar Rp {total_rev - total_exp:,.0f}. Kinerja stabil."
    else:
        ai_summary += "Belum ada aktivitas transaksi yang tercatat pada periode ini."

    new_report = Report(
        user_id=current_user.id,
        type=type,
        start_date=start_date,
        end_date=end_date,
        total_revenue=total_rev,
        total_transactions=total_count,
        ai_summary=ai_summary
    )
    db.add(new_report)
    db.commit()
    db.refresh(new_report)
    return new_report
