from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey, Numeric, Date, UniqueConstraint
from sqlalchemy.orm import relationship, sessionmaker, declarative_base
from database import Base
import datetime

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    full_name = Column(String, nullable=True)
    upi_id = Column(String, unique=True, index=True, nullable=True)
    preferred_currency = Column(String(3), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.now(datetime.timezone.utc))
    bank_accounts = relationship("BankAccount", back_populates="owner")
    incomes = relationship("Income", back_populates="owner")
    budgets = relationship("Budget", back_populates="owner")
    expenses = relationship("Expense", back_populates="owner")
    sent_friend_requests = relationship("Friendship", foreign_keys="[Friendship.user_one_id]", back_populates="requester")
    received_friend_requests = relationship("Friendship", foreign_keys="[Friendship.user_two_id]", back_populates="recipient")
    group_memberships = relationship("GroupMember", back_populates="user")

class Friendship(Base):
    __tablename__ = "friendships"
    id = Column(Integer, primary_key=True, index=True)
    user_one_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    user_two_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(String, nullable=False, default="pending")
    requester = relationship("User", foreign_keys=[user_one_id], back_populates="sent_friend_requests")
    recipient = relationship("User", foreign_keys=[user_two_id], back_populates="received_friend_requests")
    __table_args__ = (UniqueConstraint('user_one_id', 'user_two_id', name='_user_friendship_uc'),)

class Group(Base):
    __tablename__ = "groups"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.now(datetime.timezone.utc))
    created_by_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    creator = relationship("User")
    members = relationship("GroupMember", back_populates="group")
    expenses = relationship("GroupExpense", back_populates="group")

class GroupMember(Base):
    __tablename__ = "group_members"
    id = Column(Integer, primary_key=True, index=True)
    group_id = Column(Integer, ForeignKey("groups.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    role = Column(String, nullable=False, default="member")
    group = relationship("Group", back_populates="members")
    user = relationship("User", back_populates="group_memberships")
    __table_args__ = (UniqueConstraint('group_id', 'user_id', name='_group_user_uc'),)

# --- NEW GROUP EXPENSE MODELS ---
class GroupExpense(Base):
    __tablename__ = "group_expenses"
    id = Column(Integer, primary_key=True, index=True)
    group_id = Column(Integer, ForeignKey("groups.id"), nullable=False)
    description = Column(String, nullable=False)
    total_amount = Column(Numeric(10, 2), nullable=False)
    created_by_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.now(datetime.timezone.utc))
    
    group = relationship("Group", back_populates="expenses")
    creator = relationship("User")
    participants = relationship("ExpenseParticipant", back_populates="expense")
    debts = relationship("TransactionDebt", back_populates="expense")

class ExpenseParticipant(Base):
    __tablename__ = "expense_participants"
    id = Column(Integer, primary_key=True, index=True)
    expense_id = Column(Integer, ForeignKey("group_expenses.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    paid_amount = Column(Numeric(10, 2), default=0.0)
    share_amount = Column(Numeric(10, 2), default=0.0)
    
    expense = relationship("GroupExpense", back_populates="participants")
    user = relationship("User")
    __table_args__ = (UniqueConstraint('expense_id', 'user_id', name='_expense_user_uc'),)

class TransactionDebt(Base):
    __tablename__ = "transaction_debts"
    id = Column(Integer, primary_key=True, index=True)
    expense_id = Column(Integer, ForeignKey("group_expenses.id"), nullable=False)
    lender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    borrower_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    
    expense = relationship("GroupExpense", back_populates="debts")
    lender = relationship("User", foreign_keys=[lender_id])
    borrower = relationship("User", foreign_keys=[borrower_id])

# --- PERSONAL FINANCE MODELS (No changes below) ---
class BankAccount(Base):
    __tablename__ = "bank_accounts"
    id = Column(Integer, primary_key=True, index=True)
    bank_name = Column(String, nullable=False)
    account_type = Column(String, nullable=False)
    balance = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), nullable=False)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    owner = relationship("User", back_populates="bank_accounts")
    incomes = relationship("Income", back_populates="bank_account")
    expenses = relationship("Expense", back_populates="bank_account")

class Income(Base):
    __tablename__ = "incomes"
    id = Column(Integer, primary_key=True, index=True)
    source = Column(String, nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), nullable=False)
    income_date = Column(Date, nullable=False)
    recurrence = Column(String, default="none")
    created_at = Column(DateTime, default=datetime.datetime.now(datetime.timezone.utc))
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    bank_account_id = Column(Integer, ForeignKey("bank_accounts.id"), nullable=False)
    owner = relationship("User", back_populates="incomes")
    bank_account = relationship("BankAccount", back_populates="incomes")

class Budget(Base):
    __tablename__ = "budgets"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    category = Column(String, nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    recurrence = Column(String, default="monthly")
    created_at = Column(DateTime, default=datetime.datetime.now(datetime.timezone.utc))
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    owner = relationship("User", back_populates="budgets")

class Expense(Base):
    __tablename__ = "expenses"
    id = Column(Integer, primary_key=True, index=True)
    description = Column(String, nullable=False)
    category = Column(String, nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), nullable=False)
    transaction_date = Column(DateTime, default=datetime.datetime.now(datetime.timezone.utc))
    payment_method = Column(String, nullable=False)
    recipient_info = Column(String, nullable=True)
    notes = Column(String, nullable=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    bank_account_id = Column(Integer, ForeignKey("bank_accounts.id"), nullable=True)
    owner = relationship("User", back_populates="expenses")
    bank_account = relationship("BankAccount", back_populates="expenses")

