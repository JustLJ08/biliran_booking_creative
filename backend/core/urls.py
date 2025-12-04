from django.urls import path # type: ignore
from .views import AdminPendingCreatives, admin_manage_creative # Import the new views
from .views import get_booking_contract, sign_contract
from .views import (
    RegisterView, LoginView,
    IndustryList, SubCategoryList, CreativeList,
    BookingCreate, BookingList, BookingDetail,
    CreateCreativeProfile, CreativeProfileDetail,
    ProductList, ProductDetail, 
    OrderList, OrderDetail, 
    ServicePackageList,
    save_user_interests, 
    recommended_creatives,
    VerifyEmailOTP, 
    ResendEmailOTP
)

urlpatterns = [
    # Auth
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),

    # Email Verification
    path("verifyEmail/", VerifyEmailOTP.as_view(), name="verify-email"),
    path("resendOtp/", ResendEmailOTP.as_view(), name="resend-otp"),

    # Data & Search
    path('industries/', IndustryList.as_view(), name='industry-list'),
    path('subcategories/', SubCategoryList.as_view(), name='subcategory-list'),
    path('creatives/', CreativeList.as_view(), name='creative-list'),

    # --- NEW: Recommendations & Interests ---
    path('save-interests/', save_user_interests, name='save-interests'),
    path('creatives/recommended/', recommended_creatives, name='recommended-creatives'),

    # Products & Orders (E-commerce)
    path('products/', ProductList.as_view(), name='product-list'),
    path('products/<int:pk>/', ProductDetail.as_view(), name='product-detail'),
    
    # Orders
    path('orders/', OrderList.as_view(), name='order-list'),
    path('orders/<int:pk>/', OrderDetail.as_view(), name='order-detail'), 
    
    path('service-packages/', ServicePackageList.as_view(), name='service-package-list'),

    # Bookings (Services)
    path('bookings/', BookingCreate.as_view(), name='booking-create'),
    path('my-bookings/', BookingList.as_view(), name='booking-list'),
    path('bookings/<int:pk>/', BookingDetail.as_view(), name='booking-detail'),

    # Profile
    path('create-profile/', CreateCreativeProfile.as_view(), name='create-profile'),
    path('creative-profile/', CreativeProfileDetail.as_view(), name='creative-profile-detail'),

    path('contract/booking/<int:booking_id>/', get_booking_contract, name='get-contract'),
    path('contract/sign/<int:contract_id>/', sign_contract, name='sign-contract'),

    #admin
    path('admin/pending-creatives/', AdminPendingCreatives.as_view(), name='admin-pending-list'),
    path('admin/manage-creative/<int:pk>/', admin_manage_creative, name='admin-manage-creative'),
]