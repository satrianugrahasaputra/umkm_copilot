from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.schemas.schemas import ProductCreate, ProductResponse
from app.models.models import Product, User
from app.services.auth_service import get_current_user

router = APIRouter(prefix="/products", tags=["Products"])

@router.get("", response_model=List[ProductResponse])
def get_products(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    products = db.query(Product).filter(Product.user_id == current_user.id).all()
    return products

@router.post("", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
def create_product(product_data: ProductCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    # Check if product name already exists for this user
    existing_product = db.query(Product).filter(
        Product.user_id == current_user.id,
        Product.name.ilike(product_data.name)
    ).first()
    if existing_product:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Produk dengan nama '{product_data.name}' sudah terdaftar"
        )
    
    new_product = Product(
        user_id=current_user.id,
        name=product_data.name,
        description=product_data.description,
        price=product_data.price,
        stock=product_data.stock,
        unit=product_data.unit
    )
    db.add(new_product)
    db.commit()
    db.refresh(new_product)
    return new_product
