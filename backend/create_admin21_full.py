import os
import django
from django.contrib.auth import get_user_model

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

User = get_user_model()
if not User.objects.filter(username='admin21').exists():
    User.objects.create_superuser('admin21', 'admin21@example.com', 'password123')
    print("Superuser created successfully!")
else:
    print("Superuser already exists.")
