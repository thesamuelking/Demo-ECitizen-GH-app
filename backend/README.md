# GhanaServe API

This Django REST backend uses SQLite by default for local development, with JWT authentication and server-side application records.

```powershell
cd backend
py -m venv .venv

# If PowerShell blocks activation, allow this session only:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
\.\.venv\Scripts\Activate.ps1

# Or, use Command Prompt if you prefer:
# .\.venv\Scripts\activate.bat

pip install -r requirements.txt
Copy-Item .env.example .env
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

If you want MySQL instead of SQLite, start the Docker database and set `DB_ENGINE=mysql` (or remove the SQLite override), then run:

```powershell
docker compose up -d db
python manage.py makemigrations accounts applications
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

Flutter defaults to `http://10.0.2.2:8000/api` for an Android emulator. Override it with `--dart-define=API_BASE_URL=http://<host>:8000/api` for a physical device, iOS simulator, or web.
