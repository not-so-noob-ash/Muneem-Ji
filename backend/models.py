from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func

from database import Base # REMOVED the dot here

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    
    # Use func.now() to set the default value on the database server itself
    created_at = Column(DateTime(timezone=True), server_default=func.now())

