from fastapi import FastAPI
import models
from database import engine
from routers import user # Import the new user router

# This line creates the database tables
models.Base.metadata.create_all(bind=engine)

# Create an instance of the FastAPI class
app = FastAPI(title="Muneem Ji - Expense Tracker API")

# Include the user router in our main app
app.include_router(user.router)
print("All registered routes:", [route.path for route in app.routes])

@app.get("/")
def read_root():
    """A simple root endpoint to confirm the API is running."""
    return {"status": "ok", "message": "Welcome to the Muneem Ji API!"}

