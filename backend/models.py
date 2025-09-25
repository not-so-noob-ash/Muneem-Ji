import datetime
from decimal import Decimal
from sqlalchemy import (Column, Integer, String, DateTime, Numeric, ForeignKey,
                        UniqueConstraint)
from sqlalchemy.orm import relationship, declarative_base

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=True)
    email = Column(String, unique=True, index=True, nullable=False)
    upi_id = Column(String, unique=True, index=True, nullable=True)
    password_hash = Column(String, nullable=False)
    preferred_currency = Column(String(3), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationships
    bank_accounts = relationship("BankAccount", back_populates="owner")
    incomes = relationship("Income", back_populates="owner")
    budgets = relationship("Budget", back_populates="owner")
    expenses = relationship("Expense", back_populates="owner")
    created_groups = relationship("Group", back_populates="creator")
    group_memberships = relationship("GroupMember", back_populates="user")

class BankAccount(Base):
    __tablename__ = "bank_accounts"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    bank_name = Column(String, nullable=False)
    account_type = Column(String, nullable=False)
    balance = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), nullable=False)

    owner = relationship("User", back_populates="bank_accounts")
    incomes = relationship("Income", back_populates="bank_account")
    expenses = relationship("Expense", back_populates="bank_account")

class Income(Base):
    __tablename__ = "incomes"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    bank_account_id = Column(Integer, ForeignKey("bank_accounts.id"), nullable=False)
    source = Column(String, nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), nullable=False)
    income_date = Column(DateTime, default=datetime.datetime.utcnow)
    recurrence = Column(String, default="non_recurring")

    owner = relationship("User", back_populates="incomes")
    bank_account = relationship("BankAccount", back_populates="incomes")

class Budget(Base):
    __tablename__ = "budgets"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    category = Column(String, nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    recurrence = Column(String, default="monthly")

    owner = relationship("User", back_populates="budgets")

class Expense(Base):
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    bank_account_id = Column(Integer, ForeignKey("bank_accounts.id"), nullable=True)
    description = Column(String, nullable=False)
    category = Column(String, nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), nullable=False)
    transaction_date = Column(DateTime, default=datetime.datetime.utcnow)
    payment_method = Column(String, nullable=False) # 'cash' or 'upi'
    recipient_info = Column(String, nullable=True) # upi_id or name
    notes = Column(String, nullable=True)

    owner = relationship("User", back_populates="expenses")
    bank_account = relationship("BankAccount", back_populates="expenses")

class Friendship(Base):
    __tablename__ = "friendships"

    id = Column(Integer, primary_key=True, index=True)
    requester_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    recipient_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(String, default="pending") # pending, accepted, declined

    requester = relationship("User", foreign_keys=[requester_id])
    recipient = relationship("User", foreign_keys=[recipient_id])

    __table_args__ = (UniqueConstraint('requester_id', 'recipient_id', name='_requester_recipient_uc'),)

class Group(Base):
    __tablename__ = "groups"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    creator_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    creator = relationship("User", back_populates="created_groups")
    members = relationship("GroupMember", back_populates="group")
    expenses = relationship("GroupExpense", back_populates="group")

class GroupMember(Base):
    __tablename__ = "group_members"

    id = Column(Integer, primary_key=True, index=True)
    group_id = Column(Integer, ForeignKey("groups.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    role = Column(String, default="member") # admin, member

    group = relationship("Group", back_populates="members")
    user = relationship("User", back_populates="group_memberships")

    __table_args__ = (UniqueConstraint('group_id', 'user_id', name='_group_user_uc'),)

class GroupExpense(Base):
    __tablename__ = "group_expenses"

    id = Column(Integer, primary_key=True, index=True)
    group_id = Column(Integer, ForeignKey("groups.id"), nullable=False)
    description = Column(String, nullable=False)
    total_amount = Column(Numeric(10, 2), nullable=False)
    creator_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    transaction_date = Column(DateTime, default=datetime.datetime.utcnow)

    group = relationship("Group", back_populates="expenses")
    creator = relationship("User")
    participants = relationship("ExpenseParticipant", back_populates="group_expense")
    # --- RELATIONSHIP TO DEBTS (NEW) ---
    debts = relationship("TransactionDebt", back_populates="group_expense")

class ExpenseParticipant(Base):
    __tablename__ = "expense_participants"
    
    id = Column(Integer, primary_key=True, index=True)
    expense_id = Column(Integer, ForeignKey("group_expenses.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    paid_amount = Column(Numeric(10, 2), nullable=False)
    share_amount = Column(Numeric(10, 2), nullable=False)

    group_expense = relationship("GroupExpense", back_populates="participants")
    user = relationship("User")

class TransactionDebt(Base):
    __tablename__ = "transaction_debts"

    id = Column(Integer, primary_key=True, index=True)
    expense_id = Column(Integer, ForeignKey("group_expenses.id"), nullable=False)
    lender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    borrower_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    
    # --- THE MISSING RELATIONSHIP (NEW) ---
    group_expense = relationship("GroupExpense", back_populates="debts")
    lender = relationship("User", foreign_keys=[lender_id])
    borrower = relationship("User", foreign_keys=[borrower_id])

class Settlement(Base):
    __tablename__ = "settlements"

    id = Column(Integer, primary_key=True, index=True)
    group_id = Column(Integer, ForeignKey("groups.id"), nullable=False)
    payer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    payee_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    settlement_date = Column(DateTime, default=datetime.datetime.utcnow)

    group = relationship("Group")
    payer = relationship("User", foreign_keys=[payer_id])
    payee = relationship("User", foreign_keys=[payee_id])

