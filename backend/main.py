from fastapi import FastAPI
import models
from database import engine
from routers import user, bank_account, income, budget, dashboard, expense # Import the new expense router

# Create all database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Muneem Ji - Expense Tracker API",
    description="API for managing personal and group expenses.",
    version="0.1.0",
)

# Include the routers
app.include_router(user.router)
app.include_router(bank_account.router)
app.include_router(income.router)
app.include_router(budget.router)
app.include_router(dashboard.router)
app.include_router(expense.router) # Add the new expense router

@app.get("/")
def read_root():
    """
    A simple root endpoint to confirm the API is running.
    """
    return {"status": "ok", "message": "Welcome to the Muneem Ji API!"}

