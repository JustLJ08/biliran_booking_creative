from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

# NOTE: This file is the main entry point for URL routing (ROOT_URLCONF).

urlpatterns = [
    # Django Admin Site
    path('admin/', admin.site.urls),
    
    # API Endpoints (All API paths are routed through the 'core' app)
    path('api/', include('core.urls')), 
]

# CRITICAL FIX: This block MUST be at the ROOT level of your project's URL configuration 
# to allow Django to serve media files (images) during development (DEBUG=True).
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)