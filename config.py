import os


class Config:
    SECRET_KEY = "super-secret-key"  # change for prod
    SQLALCHEMY_DATABASE_URI = (
        os.environ.get("DATABASE_URL")
        or "postgresql://postgres:postgres@db:5432/flaskdb"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
