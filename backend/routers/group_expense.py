from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
import models
import schemas
import security
from database import get_db
from decimal import Decimal

router = APIRouter(
    prefix="/groups",
    tags=["Group Expenses"]
)

@router.post("/{group_id}/expenses", response_model=schemas.GroupExpense)
def create_group_expense(
    group_id: int,
    expense_create: schemas.GroupExpenseCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    # 1. Verify the group exists and the current user is a member
    group_member = db.query(models.GroupMember).filter(
        models.GroupMember.group_id == group_id,
        models.GroupMember.user_id == current_user.id
    ).first()

    if not group_member:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found or you are not a member."
        )

    # 2. Validate participant data
    total_paid = sum(p.paid_amount for p in expense_create.participants)
    total_share = sum(p.share_amount for p in expense_create.participants)

    if not (abs(total_paid - expense_create.total_amount) < 0.01 and abs(total_share - expense_create.total_amount) < 0.01):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The sum of paid amounts and share amounts must both equal the total expense amount."
        )

    participant_ids = {p.user_id for p in expense_create.participants}
    db_members = db.query(models.GroupMember.user_id).filter(
        models.GroupMember.group_id == group_id,
        models.GroupMember.user_id.in_(participant_ids)
    ).all()
    
    if len(db_members) != len(participant_ids):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="One or more participants are not members of this group."
        )

    # 3. Create the expense and participant records
    db_expense = models.GroupExpense(
        group_id=group_id,
        description=expense_create.description,
        total_amount=expense_create.total_amount,
        creator_id=current_user.id
    )
    db.add(db_expense)
    db.flush() # Use flush to get the ID without committing

    balances = {}
    for p_input in expense_create.participants:
        db_participant = models.ExpenseParticipant(
            expense_id=db_expense.id,
            user_id=p_input.user_id,
            paid_amount=p_input.paid_amount,
            share_amount=p_input.share_amount
        )
        db.add(db_participant)
        balance = p_input.paid_amount - p_input.share_amount
        if balance != Decimal('0.0'):
            balances[p_input.user_id] = balances.get(p_input.user_id, Decimal('0.0')) + balance

    # 4. Calculate and store the transaction debts
    lenders = {uid: bal for uid, bal in balances.items() if bal > 0}
    borrowers = {uid: -bal for uid, bal in balances.items() if bal < 0}

    while lenders and borrowers:
        lender_id, lend_amount = list(lenders.items())[0]
        borrower_id, borrow_amount = list(borrowers.items())[0]
        settle_amount = min(lend_amount, borrow_amount)

        db_debt = models.TransactionDebt(
            expense_id=db_expense.id,
            lender_id=lender_id,
            borrower_id=borrower_id,
            amount=settle_amount
        )
        db.add(db_debt)

        lenders[lender_id] -= settle_amount
        borrowers[borrower_id] -= settle_amount
        if lenders[lender_id] < Decimal('0.01'): del lenders[lender_id]
        if borrowers[borrower_id] < Decimal('0.01'): del borrowers[borrower_id]

    db.commit()
    db.refresh(db_expense)
    return db_expense


@router.get("/{group_id}/expenses", response_model=List[schemas.GroupExpense])
def get_group_expenses(
    group_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    group_member = db.query(models.GroupMember).filter(
        models.GroupMember.group_id == group_id,
        models.GroupMember.user_id == current_user.id
    ).first()

    if not group_member:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found or you are not a member."
        )

    expenses = db.query(models.GroupExpense).filter(models.GroupExpense.group_id == group_id).order_by(models.GroupExpense.transaction_date.desc()).all()
    return expenses

@router.get("/{group_id}/balance", response_model=List[schemas.GroupBalance])
def get_group_balance(
    group_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    group_member = db.query(models.GroupMember).filter(
        models.GroupMember.group_id == group_id,
        models.GroupMember.user_id == current_user.id
    ).first()

    if not group_member:
        raise HTTPException(status_code=404, detail="Group not found or user is not a member")

    # --- THIS IS THE FINAL, CORRECTED LOGIC ---
    
    # Step 1: Calculate the total net balance from all expense transactions
    all_debts = db.query(models.TransactionDebt).join(models.GroupExpense).filter(models.GroupExpense.group_id == group_id).all()
    
    balances = {}
    for debt in all_debts:
        balances[debt.lender_id] = balances.get(debt.lender_id, Decimal('0.0')) + debt.amount
        balances[debt.borrower_id] = balances.get(debt.borrower_id, Decimal('0.0')) - debt.amount

    # Step 2: Apply all settlements directly to the balances
    all_settlements = db.query(models.Settlement).filter(models.Settlement.group_id == group_id).all()

    for settlement in all_settlements:
        # Payer's balance increases (they owe less), Payee's balance decreases (they are owed less)
        balances[settlement.payer_id] = balances.get(settlement.payer_id, Decimal('0.0')) + settlement.amount
        balances[settlement.payee_id] = balances.get(settlement.payee_id, Decimal('0.0')) - settlement.amount

    # --- END OF CORRECTION ---

    lenders = {uid: bal for uid, bal in balances.items() if bal > Decimal('0.01')}
    borrowers = {uid: -bal for uid, bal in balances.items() if bal < Decimal('-0.01')}

    simplified_debts = []
    while lenders and borrowers:
        lender_id, lend_amount = list(lenders.items())[0]
        borrower_id, borrow_amount = list(borrowers.items())[0]

        settle_amount = min(lend_amount, borrow_amount)
        
        lender_user = db.query(models.User).get(lender_id)
        borrower_user = db.query(models.User).get(borrower_id)

        simplified_debts.append(
            schemas.GroupBalance(lender=lender_user, borrower=borrower_user, amount=settle_amount)
        )
        
        lenders[lender_id] -= settle_amount
        borrowers[borrower_id] -= settle_amount

        if lenders[lender_id] < Decimal('0.01'): del lenders[lender_id]
        if borrowers[borrower_id] < Decimal('0.01'): del borrowers[borrower_id]
    
    return simplified_debts

