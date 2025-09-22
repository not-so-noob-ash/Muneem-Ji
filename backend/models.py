from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey, Numeric, Date
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

    # Relationships
    bank_accounts = relationship("BankAccount", back_populates="owner")
    incomes = relationship("Income", back_populates="owner")
    budgets = relationship("Budget", back_populates="owner")
    expenses = relationship("Expense", back_populates="owner") # New relationship

class BankAccount(Base):
    __tablename__ = "bank_accounts"

    id = Column(Integer, primary_key=True, index=True)
    bank_name = Column(String, nullable=False)
    account_type = Column(String, nullable=False)
    balance = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), nullable=False)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    # Relationships
    owner = relationship("User", back_populates="bank_accounts")
    incomes = relationship("Income", back_populates="bank_account")
    expenses = relationship("Expense", back_populates="bank_account") # New relationship

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

    # Relationships
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

    # Relationship
    owner = relationship("User", back_populates="budgets")

class Expense(Base):
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True, index=True)
    description = Column(String, nullable=False)
    category = Column(String, nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), nullable=False)
    transaction_date = Column(DateTime, default=datetime.datetime.now(datetime.timezone.utc))
    payment_method = Column(String, nullable=False) # "cash" or "upi"
    recipient_info = Column(String, nullable=True) # Payee name or UPI ID
    notes = Column(String, nullable=True)
    
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    bank_account_id = Column(Integer, ForeignKey("bank_accounts.id"), nullable=True) # Optional link

    # Relationships
    owner = relationship("User", back_populates="expenses")
    bank_account = relationship("BankAccount", back_populates="expenses")

