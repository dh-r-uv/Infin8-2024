# Infin8 Project Setup Guide (WSL/Ubuntu)

Follow these steps to run the project using **WSL (Windows Subsystem for Linux)**.

## 1. Prerequisites
*   **WSL 2** enabled with **Ubuntu** installed.
*   **Docker Desktop** installed on Windows with **WSL 2 integration enabled** for your Ubuntu distro.

## 2. Configuration (`.env`)
Ensure you have a `.env` file in the **root folder** (`Infin8-2024/`).

**File:** `Infin8-2024/.env`
```env
MYSQL_DATABASE=Infin8
MYSQL_USER=admin
MYSQL_PASSWORD=admin
MYSQL_ROOT_PASSWORD=root
MYSQL_HOST=localhost
MYSQL_PORT=6000
EMAIL_HOST_USER=your_email@gmail.com
EMAIL_HOST_PASSWORD=your_app_password
```

## 3. System Dependencies (Inside WSL)
Open your Ubuntu terminal and install Python 3.10+, pip, and Ansible (for deployment).

```bash
sudo apt update
# Install Python 3.12 venv specifically as you are using Python 3.12
sudo apt install -y python3 python3-pip python3-venv python3.12-venv ansible
```

## 4. Install Project Dependencies
Navigate to the `Infin8` folder inside your repo within WSL.

```bash
# Navigate to the project folder (example path, adjust as needed)
cd /mnt/c/Users/dhruv/OneDrive\ -\ iiit-b/Desktop/sem7/SE/endsem-project/New\ folder/Infin8-2024/Infin8

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

## 5. Start Database
Start the MySQL database using Docker. Run this from the **root folder** (`Infin8-2024/`):

```bash
cd .. # Go back to root if you are in Infin8/
docker-compose up -d
```

## 6. Run the Server
Wait for the database to be ready and start the server:

```bash
cd Infin8
python manage.py wait_for_db
python manage.py runserver
```

## 7. Create Admin User
To access the Django Admin panel, you need to create a superuser.

```bash
cd Infin8
python manage.py createsuperuser
```
*   **Email**: `admin@example.com` (Used as login)
*   **Username**: `admin`
*   **Phone Number**: `1234567890` (Required by custom user model)
*   **Password**: *Enter a secure password*

## 8. Access the App
*   **Website**: [http://127.0.0.1:8000/](http://127.0.0.1:8000/)
*   **Admin Panel**: [http://127.0.0.1:8000/admin/](http://127.0.0.1:8000/admin/)

## 8. Troubleshooting

### Permission Issues
If you encounter permission denied errors, ensure you are the owner of the files or use `sudo` where appropriate (though avoid `sudo` for pip installs in venv).

### Database Reset
If you need to wipe the database:

```bash
# 1. Stop containers and remove volumes (THIS DELETES ALL DATA)
docker-compose down -v

# 2. Start fresh
docker-compose up -d --force-recreate
```
