from pydantic import BaseModel, ConfigDict, EmailStr
from typing import Optional
from decimal import Decimal
import datetime

# --- Expense Schemas ---
class ExpenseBase(BaseModel):
    description: str
    category: str
    amount: Decimal
    currency: str
    transaction_date: datetime.datetime
    payment_method: str
    bank_account_id: Optional[int] = None
    recipient_info: Optional[str] = None
    notes: Optional[str] = None

class ExpenseCreate(ExpenseBase):
    pass

class Expense(ExpenseBase):
    id: int
    owner_id: int

    model_config = ConfigDict(from_attributes=True)

# --- Dashboard Schemas ---
class DashboardSummary(BaseModel):
    net_worth: Decimal
    total_income: Decimal
    total_budgeted: Decimal
    currency: str

# --- Budget Schemas ---
class BudgetBase(BaseModel):
    title: str
    category: str
    amount: Decimal
    recurrence: str

class BudgetCreate(BudgetBase):
    pass

class Budget(BudgetBase):
    id: int
    owner_id: int

    model_config = ConfigDict(from_attributes=True)

# --- BankAccount Schemas ---
class BankAccountBase(BaseModel):
    bank_name: str
    account_type: str
    balance: Decimal
    currency: str

class BankAccountCreate(BankAccountBase):
    pass

class BankAccount(BankAccountBase):
    id: int
    owner_id: int
    
    model_config = ConfigDict(from_attributes=True)

# --- Income Schemas ---
class IncomeBase(BaseModel):
    source: str
    amount: Decimal
    currency: str
    income_date: datetime.date
    recurrence: str
    bank_account_id: int

class IncomeCreate(IncomeBase):
    pass

class Income(IncomeBase):
    id: int
    owner_id: int
    bank_account: BankAccount

    model_config = ConfigDict(from_attributes=True)

# --- User Schemas ---
class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    upi_id: Optional[str] = None
    preferred_currency: Optional[str] = None

class User(BaseModel):
    id: int
    email: EmailStr
    full_name: Optional[str] = None
    upi_id: Optional[str] = None
    preferred_currency: Optional[str] = None
    created_at: datetime.datetime
    
    model_config = ConfigDict(from_attributes=True)

# --- Token Schema ---
class Token(BaseModel):
    access_token: str
    token_type: str

