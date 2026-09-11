import os
from datetime import timedelta
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / '.env')
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', 'dev-only-change-me')
DEBUG = os.getenv('DJANGO_DEBUG', 'True').lower() == 'true'
ALLOWED_HOSTS = [host for host in os.getenv('DJANGO_ALLOWED_HOSTS', '*').split(',') if host]
INSTALLED_APPS = [
    'django.contrib.admin', 'django.contrib.auth', 'django.contrib.contenttypes',
    'django.contrib.sessions', 'django.contrib.messages', 'django.contrib.staticfiles',
    'corsheaders', 'rest_framework', 'rest_framework_simplejwt.token_blacklist',
    'accounts', 'applications',
]
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware', 'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware', 'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware', 'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
]
ROOT_URLCONF = 'config.urls'
TEMPLATES = [{'BACKEND': 'django.template.backends.django.DjangoTemplates', 'DIRS': [], 'APP_DIRS': True,
              'OPTIONS': {'context_processors': ['django.template.context_processors.request',
              'django.contrib.auth.context_processors.auth', 'django.contrib.messages.context_processors.messages']}}]
WSGI_APPLICATION = 'config.wsgi.application'
DATABASES = {'default': {'ENGINE': 'django.db.backends.mysql', 'NAME': os.getenv('MYSQL_DATABASE', 'ghanaserve'),
    'USER': os.getenv('MYSQL_USER', 'ghanaserve'), 'PASSWORD': os.getenv('MYSQL_PASSWORD', 'ghanaserve'),
    'HOST': os.getenv('MYSQL_HOST', '127.0.0.1'), 'PORT': os.getenv('MYSQL_PORT', '3306'), 'OPTIONS': {'charset': 'utf8mb4'}}}
if os.getenv('DB_ENGINE') == 'sqlite':
    DATABASES['default'] = {'ENGINE': 'django.db.backends.sqlite3', 'NAME': BASE_DIR / 'db.sqlite3'}
AUTH_USER_MODEL = 'accounts.CitizenUser'
REST_FRAMEWORK = {'DEFAULT_AUTHENTICATION_CLASSES': ('rest_framework_simplejwt.authentication.JWTAuthentication',),
                  'DEFAULT_PERMISSION_CLASSES': ('rest_framework.permissions.IsAuthenticated',)}
SIMPLE_JWT = {'ACCESS_TOKEN_LIFETIME': timedelta(minutes=30), 'REFRESH_TOKEN_LIFETIME': timedelta(days=30),
               'ROTATE_REFRESH_TOKENS': True, 'BLACKLIST_AFTER_ROTATION': True}
CORS_ALLOW_ALL_ORIGINS = DEBUG
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Africa/Accra'
USE_I18N = True
USE_TZ = True
STATIC_URL = 'static/'
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
