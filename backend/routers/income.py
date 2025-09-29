from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import models, schemas, security
from database import get_db
from typing import List
import datetime

# CORRECTED: The prefix should not have a trailing slash.
router = APIRouter(
    prefix="/income",
    tags=["Income"]
)

@router.post("", response_model=schemas.Income, status_code=status.HTTP_201_CREATED)
def create_income(
    # Use the new, more specific schema for creation
    income: schemas.IncomeCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    # First, verify the bank account exists and belongs to the user
    bank_account = db.query(models.BankAccount).filter(
        models.BankAccount.id == income.bank_account_id,
        models.BankAccount.owner_id == current_user.id
    ).first()

    if not bank_account:
        raise HTTPException(
            status_code=status.HTTP_404, 
            detail="Bank account not found or you do not have permission to access it."
        )
    
    # Create the new income record using data from the request and auto-generated values
    new_income = models.Income(
        source=income.source,
        amount=income.amount,
        recurrence=income.recurrence,
        bank_account_id=income.bank_account_id,
        owner_id=current_user.id,
        currency=bank_account.currency, # Inherit currency from the bank account
        income_date=datetime.datetime.utcnow() # Set the date automatically
    )
    
    # Update the bank account balance
    bank_account.balance += income.amount

    db.add(new_income)
    db.add(bank_account) # Add the updated bank account to the session as well
    db.commit()
    db.refresh(new_income)
    
    return new_income

@router.get("", response_model=List[schemas.Income])
def read_incomes(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    return db.query(models.Income).filter(models.Income.owner_id == current_user.id).all()

