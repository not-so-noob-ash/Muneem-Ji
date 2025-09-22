from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import models, schemas, security

router = APIRouter(
    prefix="/expenses",
    tags=["Expenses"]
)

# Dependency to get a database session
def get_db():
    return next(security.get_db())

@router.post("/", response_model=schemas.Expense, status_code=status.HTTP_201_CREATED)
def create_expense(
    expense: schemas.ExpenseCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Create a new expense record for the logged-in user.
    - If payment_method is 'upi', bank_account_id is required and balance is deducted.
    - If payment_method is 'cash', bank_account_id is optional. If provided,
      it's treated as a withdrawal and the balance is deducted.
    """
    bank_account = None

    # Logic for UPI payments
    if expense.payment_method.lower() == "upi":
        if not expense.bank_account_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Bank account ID is required for UPI payments."
            )
        
        bank_account = db.query(models.BankAccount).filter(
            models.BankAccount.id == expense.bank_account_id,
            models.BankAccount.owner_id == current_user.id
        ).first()

        if not bank_account:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Bank account with id {expense.bank_account_id} not found."
            )
        
        bank_account.balance -= expense.amount

    # Logic for Cash payments
    elif expense.payment_method.lower() == "cash":
        # If a bank account is provided for a cash transaction, it's a withdrawal
        if expense.bank_account_id:
            bank_account = db.query(models.BankAccount).filter(
                models.BankAccount.id == expense.bank_account_id,
                models.BankAccount.owner_id == current_user.id
            ).first()

            if not bank_account:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Bank account with id {expense.bank_account_id} not found."
                )
            
            bank_account.balance -= expense.amount
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid payment method. Must be 'upi' or 'cash'."
        )

    # Create the expense record
    new_expense = models.Expense(
        **expense.model_dump(),
        owner_id=current_user.id
    )

    db.add(new_expense)
    if bank_account:
        db.add(bank_account)
    
    db.commit()
    db.refresh(new_expense)
    
    return new_expense

@router.get("/", response_model=List[schemas.Expense])
def read_expenses(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Retrieve all expense records for the currently logged-in user.
    """
    expenses = db.query(models.Expense).filter(models.Expense.owner_id == current_user.id).all()
    return expenses

