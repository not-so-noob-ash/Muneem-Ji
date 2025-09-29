from fastapi import FastAPI
from database import engine
import models
from routers import user, bank_account, income, budget, dashboard, expense, friend, group, group_expense, settlement, analytics

# This command creates all the database tables based on the models
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Muneem Ji - Expense Tracker API",
    description="A comprehensive API for personal and group expense tracking.",
    version="0.1.0",
)

# Include all the routers
app.include_router(user.router)
app.include_router(bank_account.router)
app.include_router(income.router)
app.include_router(budget.router)
app.include_router(dashboard.router)
app.include_router(expense.router)
app.include_router(friend.router)
app.include_router(group.router)
app.include_router(group_expense.router)
app.include_router(settlement.router)
# app.include_router(analytics.router)

@app.get("/", tags=["Root"])
def read_root():
    """A simple root endpoint to confirm the API is running."""
    return {"status": "ok", "message": "Welcome to the Muneem Ji API!"}

