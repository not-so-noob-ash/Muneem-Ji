import datetime
from decimal import Decimal
from sqlalchemy.orm import sessionmaker
from database import engine
import models
import security

# Create a new session for the script
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

# --- NEW: CREATE TABLES ---
# This is the crucial addition. It ensures that all tables from your models are
# created in the database if they don't already exist.
print("--- Ensuring all database tables exist ---")
models.Base.metadata.create_all(bind=engine)
print("Tables are ready.")

def seed_database():
    """
    Clears and populates the database with a complete set of test data.
    """
    print("--- Starting database seeding ---")

    # --- 1. CLEAR EXISTING DATA ---
    # Delete in reverse order of creation to respect foreign key constraints
    print("Clearing existing data...")
    db.query(models.Settlement).delete()
    db.query(models.TransactionDebt).delete()
    db.query(models.ExpenseParticipant).delete()
    db.query(models.GroupExpense).delete()
    db.query(models.GroupMember).delete()
    db.query(models.Group).delete()
    db.query(models.Friendship).delete()
    db.query(models.Expense).delete()
    db.query(models.Budget).delete()
    db.query(models.Income).delete()
    db.query(models.BankAccount).delete()
    db.query(models.User).delete()
    db.commit()
    print("Data cleared.")

    # --- 2. CREATE USERS ---
    print("Creating users...")
    users_data = [
        {"full_name": "Aman Sharma", "email": "aman@example.com", "upi_id": "aman@upi", "password": "password123"},
        {"full_name": "Priya Singh", "email": "priya@example.com", "upi_id": "priya@upi", "password": "password123"},
        {"full_name": "Vikram Kumar", "email": "vikram@example.com", "upi_id": "vikram@upi", "password": "password123"},
        {"full_name": "Neha Reddy", "email": "neha@example.com", "upi_id": "neha@upi", "password": "password123"},
    ]
    
    created_users = {}
    for user_data in users_data:
        hashed_password = security.get_password_hash(user_data["password"])
        new_user = models.User(
            full_name=user_data["full_name"],
            email=user_data["email"],
            upi_id=user_data["upi_id"],
            password_hash=hashed_password,
            preferred_currency="INR"
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        created_users[user_data["email"]] = new_user
    print(f"{len(created_users)} users created.")

    # --- 3. CREATE FRIENDSHIPS ---
    print("Creating friendships...")
    aman = created_users["aman@example.com"]
    priya = created_users["priya@example.com"]
    vikram = created_users["vikram@example.com"]
    
    friendship1 = models.Friendship(requester=aman, recipient=priya, status="accepted")
    friendship2 = models.Friendship(requester=aman, recipient=vikram, status="accepted")
    db.add_all([friendship1, friendship2])
    db.commit()
    print("Friendships created.")

    # --- 4. CREATE GROUPS AND MEMBERS ---
    print("Creating groups and members...")
    goa_trip = models.Group(name="Goa Trip", creator=aman)
    db.add(goa_trip)
    db.commit()
    
    # Aman is creator, auto-added as admin
    # We must add this manually in the seeder
    creator_as_member = models.GroupMember(group=goa_trip, user=aman, role="admin")

    member_priya = models.GroupMember(group=goa_trip, user=priya, role="member")
    member_vikram = models.GroupMember(group=goa_trip, user=vikram, role="member")
    db.add_all([creator_as_member, member_priya, member_vikram])
    db.commit()
    print("Goa Trip group created with 3 members.")

    # --- 5. CREATE A COMPLEX GROUP EXPENSE ---
    print("Creating a complex group expense...")
    # Scenario: Dinner worth 3000. Aman pays 2000, Priya pays 1000.
    # Split: Aman's share is 500, Priya's is 1000, Vikram's is 1500.
    dinner_expense = models.GroupExpense(
        group=goa_trip,
        description="Dinner at Beach Shack",
        total_amount=Decimal("3000.00"),
        creator=aman
    )
    db.add(dinner_expense)
    db.flush() # Get the ID for participants

    participants_data = [
        {"user": aman, "paid": "2000.00", "share": "500.00"},
        {"user": priya, "paid": "1000.00", "share": "1000.00"},
        {"user": vikram, "paid": "0.00", "share": "1500.00"}
    ]
    
    balances = {}
    for p_data in participants_data:
        participant = models.ExpenseParticipant(
            expense_id=dinner_expense.id,
            user_id=p_data["user"].id,
            paid_amount=Decimal(p_data["paid"]),
            share_amount=Decimal(p_data["share"])
        )
        db.add(participant)
        balance = participant.paid_amount - participant.share_amount
        if balance != 0:
            balances[p_data["user"].id] = balance
    
    # Replicate the debt calculation logic
    lenders = {uid: bal for uid, bal in balances.items() if bal > 0}
    borrowers = {uid: -bal for uid, bal in balances.items() if bal < 0}

    while lenders and borrowers:
        lender_id, lend_amount = list(lenders.items())[0]
        borrower_id, borrow_amount = list(borrowers.items())[0]
        settle_amount = min(lend_amount, borrow_amount)
        
        debt = models.TransactionDebt(expense_id=dinner_expense.id, lender_id=lender_id, borrower_id=borrower_id, amount=settle_amount)
        db.add(debt)
        
        lenders[lender_id] -= settle_amount
        borrowers[borrower_id] -= settle_amount
        if lenders[lender_id] < Decimal('0.01'): del lenders[lender_id]
        if borrowers[borrower_id] < Decimal('0.01'): del borrowers[borrower_id]
        
    db.commit()
    print("Dinner expense created. Vikram owes Aman 1500.")

    # --- 6. CREATE A SETTLEMENT ---
    print("Creating a settlement...")
    # Vikram pays Aman back 500 of the 1500 he owes.
    settlement = models.Settlement(
        group=goa_trip,
        payer=vikram,
        payee=aman,
        amount=Decimal("500.00")
    )
    db.add(settlement)
    db.commit()
    print("Settlement created. Vikram now owes Aman 1000.")

    print("--- Database seeding finished successfully! ---")

if __name__ == "__main__":
    seed_database()

