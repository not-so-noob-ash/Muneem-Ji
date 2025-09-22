from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List
import models, schemas, security
from database import SessionLocal

router = APIRouter(
    prefix="/bank-accounts",
    tags=["Bank Accounts"]
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=schemas.BankAccount, status_code=status.HTTP_201_CREATED)
def create_bank_account(
    bank_account: schemas.BankAccountCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Create a new bank account for the currently logged-in user.
    """
    new_bank_account = models.BankAccount(
        **bank_account.model_dump(),
        owner_id=current_user.id
    )
    db.add(new_bank_account)
    db.commit()
    db.refresh(new_bank_account)
    return new_bank_account

@router.get("/", response_model=List[schemas.BankAccount])
def read_bank_accounts(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Retrieve all bank accounts for the currently logged-in user.
    """
    accounts = db.query(models.BankAccount).filter(models.BankAccount.owner_id == current_user.id).all()
    return accounts

