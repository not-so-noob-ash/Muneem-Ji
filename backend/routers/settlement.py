from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import models, schemas, security

router = APIRouter(
    prefix="/groups/{group_id}/settlements",
    tags=["Settlements"]
)

# Dependency to get a database session
def get_db():
    return next(security.get_db())

@router.post("/", response_model=schemas.Settlement, status_code=status.HTTP_201_CREATED)
def create_settlement(
    group_id: int,
    settlement_data: schemas.SettlementCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Record a settlement payment from the current user to another user in the group.
    """
    # 1. VALIDATION
    # Check if the current user (payer) is a member of the group
    payer_membership = db.query(models.GroupMember).filter(
        models.GroupMember.group_id == group_id,
        models.GroupMember.user_id == current_user.id
    ).first()
    if not payer_membership:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not a member of this group.")

    # Check if the payee is a member of the group
    payee_membership = db.query(models.GroupMember).filter(
        models.GroupMember.group_id == group_id,
        models.GroupMember.user_id == settlement_data.payee_id
    ).first()
    if not payee_membership:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payee is not a member of this group.")
    
    if current_user.id == settlement_data.payee_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot settle a payment with yourself.")
        
    # 2. CREATE SETTLEMENT RECORD
    new_settlement = models.Settlement(
        group_id=group_id,
        payer_id=current_user.id,
        payee_id=settlement_data.payee_id,
        amount=settlement_data.amount
    )
    db.add(new_settlement)
    db.commit()
    db.refresh(new_settlement)
    
    return new_settlement

@router.get("/", response_model=List[schemas.Settlement])
def get_group_settlements(
    group_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Get a list of all settlement payments made within a group.
    """
    # Check if the current user is a member of the group
    membership = db.query(models.GroupMember).filter(
        models.GroupMember.group_id == group_id,
        models.GroupMember.user_id == current_user.id
    ).first()
    if not membership:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not a member of this group.")

    settlements = db.query(models.Settlement).filter(models.Settlement.group_id == group_id).order_by(models.Settlement.settlement_date.desc()).all()
    return settlements
