from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Database URL format: "postgresql://user:password@host:port/dbname"
# We are using the credentials you defined in your docker-compose.yml file.
SQLALCHEMY_DATABASE_URL = "postgresql://myuser:mypassword@localhost:5432/muneemdb"

# The engine is the main entry point to the database.
engine = create_engine(SQLALCHEMY_DATABASE_URL)

# Each instance of SessionLocal will be a new database session.
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# This Base class will be used as the parent class for all our database models.
Base = declarative_base()
