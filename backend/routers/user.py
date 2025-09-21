from fastapi import APIRouter, Depends, HTTPException, status
# NEW: Import OAuth2PasswordRequestForm
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
import models, schemas, security
from database import SessionLocal

router = APIRouter(tags=["Users"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- Register Endpoint (already exists) ---
@router.post("/register", response_model=schemas.User, status_code=status.HTTP_201_CREATED)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    hashed_password = security.hash_password(user.password)
    new_user = models.User(
        full_name=user.full_name,
        email=user.email,
        password_hash=hashed_password
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


# --- NEW: Login Endpoint ---
@router.post("/token", response_model=schemas.Token)
def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """
    Endpoint to login and receive a JWT access token.
    FastAPI expects the email in the 'username' field of the form data.
    """
    # 1. Find the user by their email (which comes in the 'username' field)
    user = db.query(models.User).filter(models.User.email == form_data.username).first()

    # 2. If no user is found OR the password is incorrect, raise an error
    if not user or not security.verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 3. If credentials are correct, create a new access token
    access_token = security.create_access_token(
        data={"sub": user.email} # "sub" is a standard JWT claim for "subject"
    )

    # 4. Return the token
    return {"access_token": access_token, "token_type": "bearer"}

