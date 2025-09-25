from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# Make sure this URL matches your docker-compose.yml
SQLALCHEMY_DATABASE_URL = "postgresql://myuser:mypassword@localhost:5432/muneemdb"

engine = create_engine(SQLALCHEMY_DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# --- THIS IS THE CRUCIAL FUNCTION THAT WAS MISSING ---
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

