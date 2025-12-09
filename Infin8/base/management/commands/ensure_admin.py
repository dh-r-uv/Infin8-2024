
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
import os

class Command(BaseCommand):
    help = 'Creates an admin user non-interactively if it does not exist'

    def handle(self, *args, **options):
        User = get_user_model()
        
        # Default credentials
        username = 'admin'
        password = 'admin123'
        email = 'admin@example.com'

        # Vault Integration
        import hvac
        import os
        
        VAULT_ADDR = os.getenv('VAULT_ADDR')
        VAULT_TOKEN = os.getenv('VAULT_DEV_ROOT_TOKEN_ID', 'root')

        if VAULT_ADDR:
            try:
                client = hvac.Client(url=VAULT_ADDR, token=VAULT_TOKEN)
                if client.is_authenticated():
                    print("ensure_admin: Connected to Vault! Fetching admin credentials...")
                    # Attempt to read secret
                    secret_response = client.secrets.kv.v2.read_secret_version(path='infin8')
                    vault_data = secret_response['data']['data']
                    
                    username = vault_data.get('ADMIN_USER', username)
                    password = vault_data.get('ADMIN_PASSWORD', password)
                    email = vault_data.get('ADMIN_EMAIL', email)
                    print("ensure_admin: Admin credentials loaded from Vault.")
            except Exception as e:
                print(f"ensure_admin: Vault connection failed: {e}. Using defaults.")

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
