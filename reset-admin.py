from app import create_app, db
from app.models import User

app = create_app()
with app.app_context():
    user = User.query.filter_by(username="admin").first()
    if user:
        db.session.delete(user)
        db.session.commit()
        print("Deleted existing user")

    u = User(username="admin", password="admin")
    db.session.add(u)
    db.session.commit()
    print("Recreated user")
