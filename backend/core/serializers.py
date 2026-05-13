from rest_framework import serializers # type: ignore
from .models import User, IndustryCategory, SubCategory, CreativeProfile, Booking, ServicePackage, Product, Order , Contract, ChatMessage, SearchHistory

# --- NEW: Registration Serializer ---
class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['id', 'username', 'password', 'email', 'first_name', 'last_name', 'role']
        read_only_fields = ['id']

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role=validated_data.get('role', 'client')
        )
        return user


# --- EXISTING SERIALIZERS ---

class UserSerializer(serializers.ModelSerializer):
    is_email_verified = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'is_email_verified']

    def get_is_email_verified(self, obj):
        return hasattr(obj, 'email_otp') and obj.email_otp.is_verified

class IndustryCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = IndustryCategory
        fields = ['id', 'name', 'icon_code', 'description']


class SubCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = SubCategory
        fields = ['id', 'name', 'industry']


class ServicePackageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServicePackage
        fields = ['id', 'creative', 'title', 'description', 'price', 'delivery_time']


# -------------------------------
#  PRODUCT SERIALIZER
# -------------------------------
class ProductSerializer(serializers.ModelSerializer):
    # Read-only computed URL for displaying the image (renamed to avoid overriding writable model field)
    image_display_url = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = ['id', 'creative', 'name', 'description', 'price', 'stock', 'image_url', 'image_display_url']
        extra_kwargs = {
            'image_url': {'write_only': True, 'required': False},
        }

    def get_image_display_url(self, obj):
        request = self.context.get('request')

        if obj.image_url:
            try:
                url = obj.image_url.url
                # Cloudinary returns full absolute URLs — don't wrap them
                if url.startswith('http') and 'cloudinary.com' in url:
                    return url
                # Other absolute URLs — return as-is
                if url.startswith('http'):
                    return url
                # Local/relative URLs need the request context
                if request:
                    return request.build_absolute_uri(url)
                return url
            except Exception as e:
                import logging
                logging.getLogger(__name__).warning(f"Error getting image URL for Product {obj.id}: {e}")
                return None

        return None




class OrderSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    client_name = serializers.CharField(source='client.username', read_only=True)

    class Meta:
        model = Order
        fields = ['id', 'client', 'client_name', 'product', 'product_name', 
                  'quantity', 'total_price', 'status', 'created_at']


# -------------------------------
#  CREATIVE PROFILE SERIALIZER
# -------------------------------
class CreativeProfileSerializer(serializers.ModelSerializer):
    # 1. User Info
    user = UserSerializer(read_only=True)
    
    # 2. SubCategory
    sub_category = SubCategorySerializer(read_only=True)
    sub_category_id = serializers.PrimaryKeyRelatedField(
        queryset=SubCategory.objects.all(), source='sub_category', write_only=True
    )

    # 3. Helper Fields
    role_name = serializers.CharField(source='sub_category.name', read_only=True)
    industry_name = serializers.CharField(source='sub_category.industry.name', read_only=True)
    
    # 4. Nested Data
    packages = ServicePackageSerializer(many=True, read_only=True)
    products = ProductSerializer(many=True, read_only=True)

    # 5. Profile Image URL
    profile_image_url = serializers.SerializerMethodField()

    # 6. National ID Image URL
    national_id_image_url = serializers.SerializerMethodField()

    class Meta:
        model = CreativeProfile
        fields = [
            'id', 'user', 'role_name', 'industry_name',
            'sub_category', 'sub_category_id',
            'bio', 'hourly_rate', 'rating', 'portfolio_url',
            'profile_image_url', 'national_id_image_url',
            'is_verified', 'packages', 'products'
        ]

    def get_profile_image_url(self, obj):
        request = self.context.get('request')
        if obj.profile_image:
            try:
                url = obj.profile_image.url
                # Cloudinary returns full absolute URLs — don't wrap them
                if url.startswith('http') and 'cloudinary.com' in url:
                    return url
                # Other absolute URLs — return as-is
                if url.startswith('http'):
                    return url
                # Local/relative URLs need the request context
                if request:
                    return request.build_absolute_uri(url)
                return url
            except Exception as e:
                import logging
                logging.getLogger(__name__).warning(f"Error getting profile image URL for CreativeProfile {obj.id}: {e}")
                return None
        return None

    def get_national_id_image_url(self, obj):
        request = self.context.get('request')
        if obj.national_id_image:
            try:
                url = obj.national_id_image.url
                if url.startswith('http') and 'cloudinary.com' in url:
                    return url
                if url.startswith('http'):
                    return url
                if request:
                    return request.build_absolute_uri(url)
                return url
            except Exception as e:
                import logging
                logging.getLogger(__name__).warning(f"Error getting national ID image URL for CreativeProfile {obj.id}: {e}")
                return None
        return None


# -------------------------------
#  BOOKING SERIALIZER
# -------------------------------
class BookingSerializer(serializers.ModelSerializer):
    creative_name = serializers.CharField(source='creative.user.first_name', read_only=True)
    creative_role = serializers.CharField(source='creative.sub_category.name', read_only=True)
    creative_user_id = serializers.IntegerField(source='creative.user.id', read_only=True)
    client_name = serializers.CharField(source='client.username', read_only=True)
    payment_proof_url = serializers.SerializerMethodField()

    class Meta:
        model = Booking
        fields = [
            'id', 'client', 'client_name',
            'creative', 'creative_name', 'creative_role', 'creative_user_id',
            'booking_date', 'booking_time', 'project_type',
            'requirements', 'status', 'created_at', 'payment_proof_url'
        ]

    def get_payment_proof_url(self, obj):
        request = self.context.get('request')
        if obj.payment_proof:
            try:
                url = obj.payment_proof.url
                if url.startswith('http') and 'cloudinary.com' in url:
                    return url
                if url.startswith('http'):
                    return url
                if request:
                    return request.build_absolute_uri(url)
                return url
            except Exception as e:
                import logging
                logging.getLogger(__name__).warning(f"Error getting payment proof URL for Booking {obj.id}: {e}")
                return None
        return None

class ContractSerializer(serializers.ModelSerializer):
    class Meta:
        model = Contract
        fields = ['id', 'booking', 'body_text', 'is_client_signed', 'is_creative_signed', 'created_at']

# ==============================
# OTP VERIFICATION SERIALIZERS
# ==============================
class VerifyOTPSerializer(serializers.Serializer):
    user_id = serializers.IntegerField()
    otp = serializers.CharField(max_length=6)


class ResendOTPSerializer(serializers.Serializer):
    user_id = serializers.IntegerField()


# ===========================================
#  CHAT MESSAGE SERIALIZER (UPDATED)
# =========================================== 

class ChatMessageSerializer(serializers.ModelSerializer):
    sender_id = serializers.IntegerField(source='sender.id', read_only=True)
    # Optional: Add sender name for easier UI display
    sender_name = serializers.CharField(source='sender.username', read_only=True)

    class Meta:
        model = ChatMessage
        # IMPORTANT: Ensure 'message' matches your model field name. 
        # If your model uses 'content', change 'message' to 'content' here.
        fields = ['id', 'booking', 'sender', 'sender_id', 'sender_name', 'message', 'created_at']
        
        # FIX: Make booking read-only so the serializer doesn't complain it's missing from the body
        read_only_fields = ['booking', 'created_at']


# ===========================================
#  SEARCH HISTORY SERIALIZER
# ===========================================

class SearchHistorySerializer(serializers.ModelSerializer):
    sub_category_name = serializers.CharField(source='sub_category.name', read_only=True, default=None)

    class Meta:
        model = SearchHistory
        fields = ['id', 'user', 'query', 'sub_category', 'sub_category_name', 'created_at']
        read_only_fields = ['created_at']