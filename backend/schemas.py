from pydantic import BaseModel, EmailStr
from datetime import datetime

# --- User Schemas (already exist) ---
class UserCreate(BaseModel):
    full_name: str
    email: EmailStr
    password: str

class User(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    created_at: datetime

    class Config:
        orm_mode = True

# --- NEW: Token Schema ---
class Token(BaseModel):
    access_token: str
    token_type: str

