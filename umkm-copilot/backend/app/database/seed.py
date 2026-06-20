import datetime
from sqlalchemy.orm import Session
from app.database import SessionLocal, Base, engine
from app.models.models import User, Product, Transaction, Insight, AISession, AIMessage
from app.services.auth_service import AuthService

def seed_database():
    # Make sure tables exist
    Base.metadata.create_all(bind=engine)
    
    db: Session = SessionLocal()
    try:
        # Check if user already exists
        test_email = "admin@umkmcopilot.id"
        db_user = db.query(User).filter(User.email == test_email).first()
        if db_user:
            print("Database has already been seeded.")
            return

        print("Seeding database with initial mock data...")
        
        # 1. Create User
        hashed_password = AuthService.hash_password("password123")
        user = User(
            email=test_email,
            password_hash=hashed_password,
            fullname="Budi Santoso",
            business_name="Warkop Budi Sejahtera",
            phone_number="081234567890"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        print(f"Created User: {user.email}")

        # 2. Create Products
        products_data = [
            {"name": "Kopi Gayo", "description": "Kopi Gayo khas Aceh kualitas premium", "price": 18000.0, "stock": 50, "unit": "cup"},
            {"name": "Teh Melati", "description": "Teh wangi melati tubruk manis", "price": 6000.0, "stock": 100, "unit": "cup"},
            {"name": "Keripik Singkong", "description": "Keripik singkong pedas manis renyah", "price": 12000.0, "stock": 35, "unit": "bungkus"},
            {"name": "Roti Bakar Cokelat", "description": "Roti bakar dengan selai cokelat tebal", "price": 15000.0, "stock": 20, "unit": "porsi"},
            {"name": "Sabun Herbal", "description": "Sabun mandi ekstrak sereh alami", "price": 8500.0, "stock": 15, "unit": "pcs"}
        ]
        
        products = []
        for p_info in products_data:
            p = Product(
                user_id=user.id,
                name=p_info["name"],
                description=p_info["description"],
                price=p_info["price"],
                stock=p_info["stock"],
                unit=p_info["unit"]
            )
            db.add(p)
            products.append(p)
        db.commit()
        print(f"Seeded {len(products)} products.")

        # 3. Create Transactions
        now = datetime.datetime.utcnow()
        transactions_data = [
            # 3 days ago
            {"type": "income", "amount": 180000.0, "description": "Penjualan 10 Kopi Gayo", "timestamp": now - datetime.timedelta(days=3)},
            {"type": "income", "amount": 60000.0, "description": "Penjualan 10 Teh Melati", "timestamp": now - datetime.timedelta(days=3)},
            {"type": "expense", "amount": 150000.0, "description": "Belanja bahan baku warkop", "timestamp": now - datetime.timedelta(days=3, hours=2)},
            
            # 2 days ago
            {"type": "income", "amount": 144000.0, "description": "Penjualan 12 Keripik Singkong", "timestamp": now - datetime.timedelta(days=2)},
            {"type": "income", "amount": 90000.0, "description": "Penjualan 6 Roti Bakar Cokelat", "timestamp": now - datetime.timedelta(days=2)},
            {"type": "expense", "amount": 40000.0, "description": "Beli gas LPG 3kg", "timestamp": now - datetime.timedelta(days=2, hours=4)},
            
            # Yesterday
            {"type": "income", "amount": 270000.0, "description": "Penjualan 15 Kopi Gayo", "timestamp": now - datetime.timedelta(days=1)},
            {"type": "income", "amount": 48000.0, "description": "Penjualan 4 Keripik Singkong", "timestamp": now - datetime.timedelta(days=1)},
            
            # Today
            {"type": "income", "amount": 90000.0, "description": "Penjualan 5 Kopi Gayo", "timestamp": now - datetime.timedelta(hours=4)},
            {"type": "income", "amount": 30000.0, "description": "Penjualan 5 Teh Melati", "timestamp": now - datetime.timedelta(hours=2)},
        ]

        for tx_info in transactions_data:
            tx = Transaction(
                user_id=user.id,
                type=tx_info["type"],
                amount=tx_info["amount"],
                description=tx_info["description"],
                timestamp=tx_info["timestamp"],
                status="completed"
            )
            db.add(tx)
        db.commit()
        print(f"Seeded {len(transactions_data)} transactions.")

        # 4. Create an Initial AI Session with some chat logs
        session = AISession(
            user_id=user.id,
            title="Catatan Pertama Budi"
        )
        db.add(session)
        db.commit()
        db.refresh(session)

        chat_logs = [
            {"sender": "user", "content": "Halo! Saya baru mulai berjualan.", "timestamp": now - datetime.timedelta(hours=6)},
            {"sender": "assistant", "content": "Halo Budi! Selamat datang di UMKM Copilot Indonesia. Saya siap membantu mencatat transaksi bisnis Anda. Anda bisa mengetik 'Saya menjual 10 kopi' atau 'Beli bahan baku Rp 50000' untuk langsung mencatatnya.", "timestamp": now - datetime.timedelta(hours=6, minutes=58)},
            {"sender": "user", "content": "Saya menjual 5 Kopi Gayo", "timestamp": now - datetime.timedelta(hours=4)},
            {"sender": "assistant", "content": "Konfirmasi Transaksi: INCOME - Kopi Gayo sejumlah 5 dengan total Rp 90,000.", "timestamp": now - datetime.timedelta(hours=4, minutes=59)}
        ]

        for msg in chat_logs:
            m = AIMessage(
                session_id=session.id,
                sender=msg["sender"],
                content=msg["content"],
                timestamp=msg["timestamp"]
            )
            db.add(m)
        db.commit()
        print("Seeded initial AI conversation chat history.")

        # 5. Create an Insight
        insight = Insight(
            user_id=user.id,
            category="sales",
            content="Kopi Gayo adalah produk paling laku di warkop Anda minggu ini, dengan kontribusi penjualan mencapai 55%. Di sisi lain, persediaan Sabun Herbal hampir habis (tersisa 15 pcs).",
            recommendation="1. Lakukan pengadaan biji Kopi Gayo tambahan untuk akhir pekan.\n2. Buat promo bundling 'Roti Bakar + Kopi Gayo' untuk meningkatkan penjualan roti bakar."
        )
        db.add(insight)
        db.commit()
        print("Seeded initial business insights.")
        print("Database seeding completed successfully.")

    except Exception as e:
        print(f"Error seeding database: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
