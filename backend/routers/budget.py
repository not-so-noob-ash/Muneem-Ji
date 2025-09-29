from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
import models, schemas, security
from database import get_db
from typing import List

# CORRECTED: The prefix should not have a trailing slash.
router = APIRouter(
    prefix="/budgets",
    tags=["Budgets"]
)

@router.post("", response_model=schemas.Budget, status_code=status.HTTP_201_CREATED)
def create_budget(
    budget: schemas.BudgetCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    new_budget = models.Budget(**budget.model_dump(), owner_id=current_user.id)
    db.add(new_budget)
    db.commit()
    db.refresh(new_budget)
    return new_budget

@router.get("", response_model=List[schemas.Budget])
def read_budgets(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    return db.query(models.Budget).filter(models.Budget.owner_id == current_user.id).all()

