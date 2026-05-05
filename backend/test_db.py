import os
import sys
import django

sys.path.append('/home/rikka-joy/Documents/GitHub/biliran_booking_creative/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.db import connection

try:
    connection.ensure_connection()
    print("Database connection successful!")
except Exception as e:
    print(f"Database connection failed: {e}")
