from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import models, schemas, security

router = APIRouter(
    prefix="/income",
    tags=["Income"]
)

# Dependency to get a database session
def get_db():
    return next(security.get_db())

@router.post("/", response_model=schemas.Income, status_code=status.HTTP_201_CREATED)
def create_income_record(
    income: schemas.IncomeCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Create a new income record for the logged-in user and update the
    corresponding bank account balance.
    """
    # Step 1: Validate that the bank account belongs to the current user
    bank_account = db.query(models.BankAccount).filter(
        models.BankAccount.id == income.bank_account_id,
        models.BankAccount.owner_id == current_user.id
    ).first()

    if not bank_account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Bank account with id {income.bank_account_id} not found or does not belong to the current user."
        )

    # Step 2: Create the new income record
    new_income = models.Income(
        **income.model_dump(),
        owner_id=current_user.id
    )
    db.add(new_income)
    
    # Step 3: Update the bank account balance
    bank_account.balance += income.amount
    db.add(bank_account)
    
    # Step 4: Commit all changes to the database
    db.commit()
    db.refresh(new_income)
    
    return new_income

@router.get("/", response_model=List[schemas.Income])
def read_income_records(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Retrieve all income records for the currently logged-in user.
    """
    incomes = db.query(models.Income).filter(models.Income.owner_id == current_user.id).all()
    return incomes
