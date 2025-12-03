from django.contrib import admin
from .models import (
    User,
    IndustryCategory,
    SubCategory,
    CreativeProfile,
    ServicePackage,
    Product,
    Booking,
    Order
)

# Custom Display for User
@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('id', 'username', 'email', 'role', 'phone_number')
    list_filter = ('role',)
    search_fields = ('username', 'email')


# Custom Display for Industry Category
@admin.register(IndustryCategory)
class IndustryCategoryAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'icon_code')
    search_fields = ('name',)


# Custom Display for Sub Category
@admin.register(SubCategory)
class SubCategoryAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'industry')
    list_filter = ('industry',)
    search_fields = ('name',)


# Creative Profile
@admin.register(CreativeProfile)
class CreativeProfileAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'sub_category', 'hourly_rate', 'rating', 'is_verified')
    list_filter = ('is_verified', 'sub_category')
    search_fields = ('user__username',)


# Service Packages
@admin.register(ServicePackage)
class ServicePackageAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'creative', 'price', 'delivery_time')
    search_fields = ('title',)


# -------------------------------
# PRODUCT ADMIN (IMPORTANT)
# -------------------------------
@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'creative', 'price', 'stock', 'image_url')
    list_filter = ('creative',)
    search_fields = ('name',)


# Booking Admin
@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ('id', 'client', 'creative', 'booking_date', 'status')
    list_filter = ('status', 'booking_date')
    search_fields = ('client__username', 'creative__user__username')


# Order Admin
@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('id', 'client', 'product', 'quantity', 'total_price', 'status', 'created_at')
    list_filter = ('status',)
    search_fields = ('client__username', 'product__name')
