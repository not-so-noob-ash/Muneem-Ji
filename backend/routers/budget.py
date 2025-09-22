from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import models, schemas, security

router = APIRouter(
    prefix="/budgets",
    tags=["Budgets"]
)

# Dependency to get a database session
def get_db():
    return next(security.get_db())

@router.post("/", response_model=schemas.Budget, status_code=status.HTTP_201_CREATED)
def create_budget(
    budget: schemas.BudgetCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Create a new budget for the logged-in user.
    """
    new_budget = models.Budget(
        **budget.model_dump(),
        owner_id=current_user.id
    )
    db.add(new_budget)
    db.commit()
    db.refresh(new_budget)
    return new_budget

@router.get("/", response_model=List[schemas.Budget])
def read_budgets(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Retrieve all budgets for the currently logged-in user.
    """
    budgets = db.query(models.Budget).filter(models.Budget.owner_id == current_user.id).all()
    return budgets
