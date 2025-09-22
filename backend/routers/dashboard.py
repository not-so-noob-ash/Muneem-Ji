from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
import models, schemas, security

router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"]
)

# Dependency to get a database session
def get_db():
    return next(security.get_db())

@router.get("/summary", response_model=schemas.DashboardSummary)
def get_dashboard_summary(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Retrieve a financial summary for the logged-in user, including
    net worth, total income, and total budget amounts.
    """
    # Calculate total balance from all bank accounts
    total_balance = db.query(func.sum(models.BankAccount.balance)).filter(
        models.BankAccount.owner_id == current_user.id
    ).scalar() or 0.0

    # For now, Net Worth is just the total balance.
    # Later, we will add assets and subtract liabilities.
    net_worth = total_balance

    # Calculate total income for the current month
    # Note: This is a simplified example. A real app might have more complex date filtering.
    total_income = db.query(func.sum(models.Income.amount)).filter(
        models.Income.owner_id == current_user.id
    ).scalar() or 0.0

    # Calculate total budgeted amount for the current month
    total_budgeted = db.query(func.sum(models.Budget.amount)).filter(
        models.Budget.owner_id == current_user.id,
        models.Budget.recurrence == "monthly" # Example: only summing monthly budgets
    ).scalar() or 0.0

    return {
        "net_worth": net_worth,
        "total_income": total_income,
        "total_budgeted": total_budgeted,
        "currency": current_user.preferred_currency or "USD" # Default currency
    }
