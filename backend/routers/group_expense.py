from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from decimal import Decimal
import models, schemas, security

router = APIRouter(
    prefix="/groups/{group_id}/expenses",
    tags=["Group Expenses"]
)

# Dependency to get a database session
def get_db():
    return next(security.get_db())

@router.post("/", response_model=schemas.GroupExpense, status_code=status.HTTP_201_CREATED)
def create_group_expense(
    group_id: int,
    expense_data: schemas.GroupExpenseCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Create a new expense within a group, calculating and storing all resulting debts.
    """
    # 1. VALIDATION
    # Check if the current user is a member of the group
    membership = db.query(models.GroupMember).filter(
        models.GroupMember.group_id == group_id,
        models.GroupMember.user_id == current_user.id
    ).first()
    if not membership:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not a member of this group.")

    # Validate that paid amounts and share amounts sum to the total
    total_paid = sum(p.paid_amount for p in expense_data.participants)
    total_share = sum(p.share_amount for p in expense_data.participants)
    
    # Use a small tolerance for floating point comparisons
    if not (abs(total_paid - expense_data.total_amount) < Decimal('0.01') and \
            abs(total_share - expense_data.total_amount) < Decimal('0.01')):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Sum of payments and shares must equal the total amount.")

    # 2. CREATE PARENT EXPENSE RECORD
    new_expense = models.GroupExpense(
        group_id=group_id,
        description=expense_data.description,
        total_amount=expense_data.total_amount,
        created_by_id=current_user.id
    )
    db.add(new_expense)
    db.flush() # Get the new_expense.id for child records

    # 3. CREATE PARTICIPANT RECORDS & CALCULATE BALANCES
    balances = {}
    for p_input in expense_data.participants:
        participant = models.ExpenseParticipant(
            expense_id=new_expense.id,
            user_id=p_input.user_id,
            paid_amount=p_input.paid_amount,
            share_amount=p_input.share_amount
        )
        db.add(participant)
        balance = p_input.paid_amount - p_input.share_amount
        if balance != 0:
            balances[p_input.user_id] = balance
    
    # 4. CALCULATE AND STORE DEBTS (DEBT SIMPLIFICATION ALGORITHM)
    lenders = {user_id: balance for user_id, balance in balances.items() if balance > 0}
    borrowers = {user_id: -balance for user_id, balance in balances.items() if balance < 0}

    while lenders and borrowers:
        lender_id, lend_amount = list(lenders.items())[0]
        borrower_id, borrow_amount = list(borrowers.items())[0]

        settle_amount = min(lend_amount, borrow_amount)

        new_debt = models.TransactionDebt(
            expense_id=new_expense.id,
            lender_id=lender_id,
            borrower_id=borrower_id,
            amount=settle_amount
        )
        db.add(new_debt)

        lenders[lender_id] -= settle_amount
        borrowers[borrower_id] -= settle_amount

        if lenders[lender_id] < Decimal('0.01'):
            del lenders[lender_id]
        if borrowers[borrower_id] < Decimal('0.01'):
            del borrowers[borrower_id]
    
    db.commit()
    db.refresh(new_expense)
    return new_expense

@router.get("/", response_model=List[schemas.GroupExpense])
def get_group_expenses(
    group_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Get a list of all expenses for a specific group.
    """
    membership = db.query(models.GroupMember).filter(
        models.GroupMember.group_id == group_id,
        models.GroupMember.user_id == current_user.id
    ).first()
    if not membership:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not a member of this group.")
        
    expenses = db.query(models.GroupExpense).filter(models.GroupExpense.group_id == group_id).order_by(models.GroupExpense.created_at.desc()).all()
    return expenses

@router.get("/balance", response_model=List[schemas.GroupBalance])
def get_group_balance(
    group_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Get the simplified overall balance sheet for the group.
    """
    membership = db.query(models.GroupMember).filter(
        models.GroupMember.group_id == group_id,
        models.GroupMember.user_id == current_user.id
    ).first()
    if not membership:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not a member of this group.")

    # Calculate net balance for each user in the group
    all_debts = db.query(models.TransactionDebt).join(models.GroupExpense).filter(models.GroupExpense.group_id == group_id).all()
    
    balances = {}
    for debt in all_debts:
        balances[debt.lender_id] = balances.get(debt.lender_id, Decimal('0.0')) + debt.amount
        balances[debt.borrower_id] = balances.get(debt.borrower_id, Decimal('0.0')) - debt.amount

    # Simplify the balances to get the final who-owes-whom list
    lenders = {user_id: balance for user_id, balance in balances.items() if balance > Decimal('0.01')}
    borrowers = {user_id: -balance for user_id, balance in balances.items() if balance < Decimal('-0.01')}
    
    simplified_debts = []
    
    # Fetch user objects for the response
    user_ids = list(lenders.keys()) + list(borrowers.keys())
    users = {user.id: user for user in db.query(models.User).filter(models.User.id.in_(user_ids)).all()}

    while lenders and borrowers:
        lender_id, lend_amount = list(lenders.items())[0]
        borrower_id, borrow_amount = list(borrowers.items())[0]

        settle_amount = min(lend_amount, borrow_amount)
        
        simplified_debts.append(schemas.GroupBalance(
            lender=users[lender_id],
            borrower=users[borrower_id],
            amount=settle_amount
        ))

        lenders[lender_id] -= settle_amount
        borrowers[borrower_id] -= settle_amount

        if lenders[lender_id] < Decimal('0.01'):
            del lenders[lender_id]
        if borrowers[borrower_id] < Decimal('0.01'):
            del borrowers[borrower_id]

    return simplified_debts
