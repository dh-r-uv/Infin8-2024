
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
import os

class Command(BaseCommand):
    help = 'Creates an admin user non-interactively if it does not exist'

    def handle(self, *args, **options):
        User = get_user_model()
        username = 'admin'
        password = 'admin123'
        email = 'admin@example.com'
        
        if not User.objects.filter(username=username).exists():
            print(f"Creating superuser '{username}'...")
            # For custom user models or standard ones
            try:
                # Assuming custom user model might have specific fields, 
                # but standard execution usually works with create_superuser
                User.objects.create_superuser(
                    username=username, 
                    email=email, 
                    password=password,
                    phone_number='1234567890' # Adding phone based on view logic hint
                )
                print(f"Superuser '{username}' created successfully.")
            except Exception as e:
                 # Fallback if phone_number is not required or different field names
                try:
                    User.objects.create_superuser(username=username, email=email, password=password)
                    print(f"Superuser '{username}' created successfully (fallback).")
                except Exception as e2:
                    print(f"Failed to create superuser: {e} | {e2}")
        else:
            print(f"Superuser '{username}' already exists.")
