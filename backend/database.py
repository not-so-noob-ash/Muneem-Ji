from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# CHANGE HERE: Updated port to 5433
SQLALCHEMY_DATABASE_URL = "postgresql://muneem_admin:secure_pass_123@127.0.0.1:5433/muneem_db"

engine = create_engine(SQLALCHEMY_DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    """
    Dependency function to get a database session for each request.
    Ensures the session is always closed after the request is finished.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()