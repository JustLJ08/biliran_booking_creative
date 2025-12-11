"""
Django settings for creative_booking project.
"""

from pathlib import Path
import os
import dj_database_url

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get("SECRET_KEY")
#SECRET_KEY = 'django-insecure-change-this-key-for-production'


# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True
#ALLOWED_HOSTS = ['*']
ALLOWED_HOSTS = [
    'biliran-booking-creative.onrender.com',
    'www.biliran-booking-creative.onrender.com',
    'localhost',
    '127.0.0.1',
]


# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'cloudinary',
    'cloudinary_storage',

    # Third-party
    'rest_framework',
    'corsheaders',

    # Local apps
    'core',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',  # Enable CORS
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

# ===============================================
# POSTGRES - CONNECT TO NEON DATABASE
# ===============================================
#DATABASES = {
#    'default': {
#        'ENGINE': 'django.db.backends.postgresql',
#        'NAME': 'creative_booking',    
#        'USER': 'neondb_owner',         
#        'PASSWORD': 'npg_kAJbVd9Rn3PH', # UPDATED: Matches the reset command above
#        'HOST': 'ep-dry-snow-a1q99rzh-pooler.ap-southeast-1.aws.neon.tech',        
#        'PORT': '5432',             # Keep as 2524 (Correct Port)
#    }
#}

DATABASES = {
    'default': dj_database_url.config(
        default=os.environ.get("DATABASE_URL"),
        conn_max_age=600,
        ssl_require=True
    )
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',},
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

DEFAULT_FILE_STORAGE = 'cloudinary_storage.storage.MediaCloudinaryStorage'

CLOUDINARY_STORAGE = {
    "CLOUD_NAME" :'db7b7izxn', 
    "API_KEY" : '849289765961966'  ,
    "API_SECRET" : 'VR2KornDc-r8zsFfLXBv63xKyx8',  
}

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'



# Custom User Model
AUTH_USER_MODEL = 'core.User'

# REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ]
}

# CORS Configuration
CORS_ALLOWED_ORIGINS = ["https://biliran-booking-creative.onrender.com","http://127.0.0.1:8000",]

#CORS_ALLOW_ALL_ORIGINS = True


#Email Config for OTP sending
#EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
#EMAIL_HOST = "smtp.gmail.com"
#EMAIL_PORT = 587
#EMAIL_USE_TLS = True
#EMAIL_HOST_USER = os.environ.get("EMAIL_HOST_USER")  # your Gmail
#EMAIL_HOST_PASSWORD = os.environ.get("EMAIL_HOST_PASSWORD")  # Gmail App Password

#DEFAULT_FROM_EMAIL = EMAIL_HOST_USER

EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"
DEFAULT_FROM_EMAIL = "no-reply@creativebook.com"



