from pydantic import BaseModel, ConfigDict, EmailStr
from typing import Optional, List
from decimal import Decimal
import datetime

# --- User Schemas (re-ordered for dependency) ---
class FriendUser(BaseModel):
    id: int
    email: EmailStr
    full_name: Optional[str] = None
    upi_id: Optional[str] = None
    model_config = ConfigDict(from_attributes=True)

# --- Group Expense Schemas ---
class ParticipantInput(BaseModel):
    user_id: int
    paid_amount: Decimal = Decimal('0.0')
    share_amount: Decimal = Decimal('0.0')

class GroupExpenseCreate(BaseModel):
    description: str
    total_amount: Decimal
    participants: List[ParticipantInput]

class TransactionDebt(BaseModel):
    lender: FriendUser
    borrower: FriendUser
    amount: Decimal
    model_config = ConfigDict(from_attributes=True)

class ExpenseParticipant(BaseModel):
    user: FriendUser
    paid_amount: Decimal
    share_amount: Decimal
    model_config = ConfigDict(from_attributes=True)
    
class GroupExpense(BaseModel):
    id: int
    description: str
    total_amount: Decimal
    created_at: datetime.datetime
    creator: FriendUser
    participants: List[ExpenseParticipant]
    debts: List[TransactionDebt]
    model_config = ConfigDict(from_attributes=True)

class GroupBalance(BaseModel):
    lender: FriendUser
    borrower: FriendUser
    amount: Decimal

# --- Group Schemas ---
class GroupMember(BaseModel):
    user: FriendUser
    role: str
    model_config = ConfigDict(from_attributes=True)

class GroupBase(BaseModel):
    name: str

class GroupCreate(GroupBase):
    pass

class Group(GroupBase):
    id: int
    created_by_id: int
    members: List[GroupMember] = []
    model_config = ConfigDict(from_attributes=True)
    
class GroupMemberAdd(BaseModel):
    user_email: EmailStr

# --- Friend Schemas ---
class FriendRequestCreate(BaseModel):
    recipient_email: EmailStr

class Friendship(BaseModel):
    id: int
    requester: FriendUser
    recipient: FriendUser
    status: str
    model_config = ConfigDict(from_attributes=True)

# --- Personal Expense Schemas ---
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
class BankAccountForIncome(BaseModel):
    id: int
    bank_name: str
    account_type: str
    model_config = ConfigDict(from_attributes=True)

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
    bank_account: BankAccountForIncome
    model_config = ConfigDict(from_attributes=True)

# --- User Schemas (continued) ---
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

