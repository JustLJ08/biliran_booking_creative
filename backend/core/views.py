from django.contrib.auth import authenticate # type: ignore
from django.shortcuts import get_object_or_404 # type: ignore
from rest_framework.views import APIView # type: ignore
from rest_framework.decorators import api_view # pyright: ignore[reportMissingImports]
from rest_framework.response import Response # type: ignore
from rest_framework import status, generics, filters # type: ignore
from django.utils import timezone # pyright: ignore[reportMissingModuleSource]
from .utils import send_otp_email
from .models import (
    User,
    Contract,
    IndustryCategory,
    SubCategory,
    CreativeProfile,
    Booking,
    Product,
    Order,
    ServicePackage,
    EmailOTP,
    UserInterest, # Ensure this is imported
)
from .serializers import (
    ContractSerializer,
    RegisterSerializer,
    IndustryCategorySerializer,
    SubCategorySerializer,
    CreativeProfileSerializer,
    BookingSerializer,
    ProductSerializer,
    OrderSerializer,
    ServicePackageSerializer,
)

# ==========================
# AUTHENTICATION VIEWS
# ==========================

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer

    def perform_create(self, serializer):
        # Save new user
        user = serializer.save()

        # Generate or update OTP
        otp_obj, _ = EmailOTP.objects.get_or_create(user=user)
        code = otp_obj.generate_otp()

        # Send OTP to email
        send_otp_email(user.email, code)



class LoginView(APIView):
    def post(self, request):
        username = request.data.get("username")
        password = request.data.get("password")
        user = authenticate(username=username, password=password)
        if user:
            return Response(
                {
                    "id": user.id,
                    "username": user.username,
                    "role": user.role,
                    "token": "dummy-token-for-now",
                }
            )
        return Response({"error": "Invalid credentials"}, status=status.HTTP_400_BAD_REQUEST)

# ==========================
# EMAIL OTP VERIFICATION
# ==========================

class VerifyEmailOTP(APIView):
    def post(self, request):
        otp = request.data.get("otp")
        user_id = request.data.get("user_id")

        try:
            otp_obj = EmailOTP.objects.get(user_id=user_id)
        except EmailOTP.DoesNotExist:
            return Response({"error": "OTP not found"}, status=404)

        if otp_obj.is_verified:
            return Response({"message": "Email already verified"}, status=200)

        if otp_obj.is_expired():
            return Response({"error": "OTP expired"}, status=400)

        if str(otp_obj.otp_code) == str(otp):
            otp_obj.is_verified = True
            otp_obj.save()
            return Response({"message": "Email verified"}, status=200)

        return Response({"error": "Invalid OTP"}, status=400)


class ResendEmailOTP(APIView):
    def post(self, request):
        user_id = request.data.get("user_id")

        try:
            otp_obj = EmailOTP.objects.get(user_id=user_id)
        except EmailOTP.DoesNotExist:
            return Response({"error": "User OTP not found"}, status=404)

        otp_obj.generate_otp()
        send_otp_email(otp_obj.user.email, otp_obj.otp_code)
        return Response({"message": "OTP resent"}, status=200)



# ==========================
# CORE DATA VIEWS
# ==========================

class IndustryList(generics.ListAPIView):
    queryset = IndustryCategory.objects.all()
    serializer_class = IndustryCategorySerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ["name", "subcategories__name"]


class SubCategoryList(generics.ListAPIView):
    serializer_class = SubCategorySerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ["name"]

    def get_queryset(self):
        queryset = SubCategory.objects.all()
        industry_id = self.request.query_params.get("industry_id")
        if industry_id:
            queryset = queryset.filter(industry_id=industry_id)
        return queryset


class CreativeList(generics.ListAPIView):
    serializer_class = CreativeProfileSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = [
        "user__username",
        "user__first_name",
        "user__last_name",
        "sub_category__name",
        "sub_category__industry__name",
    ]

    def get_queryset(self):
        queryset = CreativeProfile.objects.filter(is_verified=True)
        subcategory_id = self.request.query_params.get("subcategory_id")
        if subcategory_id:
            queryset = queryset.filter(sub_category_id=subcategory_id)
        return queryset


# ==========================
# BOOKING VIEWS
# ==========================

class BookingCreate(generics.CreateAPIView):
    queryset = Booking.objects.all()
    serializer_class = BookingSerializer


class BookingList(generics.ListAPIView):
    serializer_class = BookingSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = [
        "creative__user__username",
        "creative__user__first_name",
        "creative__user__last_name",
        "creative__sub_category__name",
        "creative__sub_category__industry__name",
    ]

    def get_queryset(self):
        queryset = Booking.objects.all()

        client_id = self.request.query_params.get("client_id")
        if client_id:
            queryset = queryset.filter(client_id=client_id)

        creative_user_id = self.request.query_params.get("creative_user_id")
        if creative_user_id:
            queryset = queryset.filter(creative__user__id=creative_user_id)

        return queryset.order_by("-created_at")


class BookingDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = Booking.objects.all()
    serializer_class = BookingSerializer


# ==========================
# PRODUCT & ORDER VIEWS
# ==========================

class ProductList(generics.ListCreateAPIView):
    """
    GET /api/products/?creative_id=3   -> list products
    POST /api/products/                -> create product
    """
    serializer_class = ProductSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ["name"]

    def get_queryset(self):
        queryset = Product.objects.all()
        creative_id = self.request.query_params.get("creative_id")
        if creative_id:
            queryset = queryset.filter(creative_id=creative_id)
        return queryset


class ProductDetail(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /api/products/<pk>/ -> retrieve single product
    PUT    /api/products/<pk>/ -> full update
    PATCH  /api/products/<pk>/ -> partial update
    DELETE /api/products/<pk>/ -> delete product
    """
    queryset = Product.objects.all()
    serializer_class = ProductSerializer


class OrderList(generics.ListCreateAPIView):
    serializer_class = OrderSerializer

    def get_queryset(self):
        queryset = Order.objects.all()

        client_id = self.request.query_params.get("client_id")
        if client_id:
            queryset = queryset.filter(client_id=client_id)

        creative_user_id = self.request.query_params.get("creative_user_id")
        if creative_user_id:
            queryset = queryset.filter(product__creative__user__id=creative_user_id)

        return queryset.order_by("-created_at")

    def perform_create(self, serializer):
        product = serializer.validated_data["product"]
        quantity = serializer.validated_data["quantity"]
        total = product.price * quantity
        serializer.save(total_price=total)

# --- NEW: ORDER DETAIL (Required for updating order status) ---
class OrderDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = Order.objects.all()
    serializer_class = OrderSerializer


class ServicePackageList(generics.ListCreateAPIView):
    serializer_class = ServicePackageSerializer

    def get_queryset(self):
        creative_id = self.request.query_params.get("creative_id")
        if creative_id:
            return ServicePackage.objects.filter(creative_id=creative_id)
        return ServicePackage.objects.all()

    def perform_create(self, serializer):
        serializer.save()


# ==========================
# PROFILE VIEWS
# ==========================

# 7. Create Creative Profile (Handles existing profiles gracefully)
class CreateCreativeProfile(APIView):
    def post(self, request):
        user_id = request.data.get("user")

        # Check if profile already exists
        if CreativeProfile.objects.filter(user_id=user_id).exists():
            return Response(
                {"message": "Profile already exists", "status": "exists"},
                status=status.HTTP_200_OK,
            )

        serializer = CreativeProfileSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            # For now, we trust the user_id sent from frontend.
            serializer.save(user_id=user_id, is_verified=False)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 8. Fetch Creative Profile by user_id
class CreativeProfileDetail(generics.RetrieveAPIView):
    serializer_class = CreativeProfileSerializer

    def get_object(self):
        user_id = self.request.query_params.get("user_id")
        return get_object_or_404(CreativeProfile, user_id=user_id)


# =========================================================
#  NEW VIEWS FOR RECOMMENDATIONS (Add this section!)
# =========================================================

@api_view(['POST'])
def save_user_interests(request):
    """
    Expects JSON: { "user_id": 1, "subcategory_ids": [10, 12, 15] }
    """
    user_id = request.data.get('user_id')
    subcategory_ids = request.data.get('subcategory_ids', [])

    if not user_id:
        return Response({"error": "User ID required"}, status=400)

    try:
        # 1. Clear old interests to avoid duplicates
        UserInterest.objects.filter(user_id=user_id).delete()

        # 2. Add new interests
        for sub_id in subcategory_ids:
            if SubCategory.objects.filter(id=sub_id).exists():
                UserInterest.objects.create(user_id=user_id, sub_category_id=sub_id)

        return Response({"message": "Interests saved successfully"}, status=200)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


@api_view(['GET'])
def recommended_creatives(request):
    """
    URL: /api/creatives/recommended/?user_id=1
    """
    user_id = request.query_params.get('user_id')

    if not user_id:
        return Response([], status=200)

    # 1. Get IDs of subcategories the user likes
    interested_sub_ids = UserInterest.objects.filter(user_id=user_id).values_list('sub_category_id', flat=True)

    if not interested_sub_ids:
        return Response([], status=200)

    # 2. Find Creatives in those categories
    # exclude(user_id=user_id) ensures the user doesn't see themselves if they are a creative
    creatives = CreativeProfile.objects.filter(sub_category_id__in=interested_sub_ids).exclude(user_id=user_id)

    # 3. Serialize and return
    serializer = CreativeProfileSerializer(creatives, many=True, context={'request': request})
    return Response(serializer.data, status=200)

# Generate or Get Contract for a Booking
@api_view(['GET'])
def get_booking_contract(request, booking_id):
    # 1. Check if booking exists
    try:
        booking = Booking.objects.get(id=booking_id)
    except Booking.DoesNotExist:
        return Response({"error": "Booking not found"}, status=404)

    # 2. Check if contract exists, if not, create one automatically
    contract, created = Contract.objects.get_or_create(booking=booking)
    
    if created:
        # Generate dynamic legal text
        client_name = booking.client.username
        creative_name = booking.creative.user.username
        date = booking.booking_date
        price = booking.creative.hourly_rate # Or package price
        
        contract.body_text = f"""
CONTRACT OF SERVICE AGREEMENT

This Agreement is made between:
CLIENT: {client_name}
PROVIDER: {creative_name}

1. SERVICES
The Provider agrees to perform services on {date} as requested in the booking requirements.

2. PAYMENT
The Client agrees to pay the rate of ${price} per hour/day upon completion.

3. CANCELLATION
Cancellations made less than 24 hours before the booking time may incur a fee.

By clicking 'Accept', both parties agree to these terms.
        """
        contract.save()

    serializer = ContractSerializer(contract)
    return Response(serializer.data)

# Sign Contract
@api_view(['POST'])
def sign_contract(request, contract_id):
    try:
        contract = Contract.objects.get(id=contract_id)
    except Contract.DoesNotExist:
        return Response({"error": "Contract not found"}, status=404)

    # Determine who is signing (based on logged in user)
    # For simplicity, we just toggle the flag sent in body, but real app should check request.user
    role = request.data.get('role') # 'client' or 'creative'
    
    if role == 'client':
        contract.is_client_signed = True
        contract.client_signed_at = timezone.now()
    elif role == 'creative':
        contract.is_creative_signed = True
        contract.creative_signed_at = timezone.now()
        
    contract.save()
    return Response({"message": "Contract signed successfully"})

# ... existing imports ...

# ==========================
# ADMIN VIEWS
# ==========================

class AdminPendingCreatives(generics.ListAPIView):
    """
    Returns a list of CreativeProfiles where is_verified = False
    """
    serializer_class = CreativeProfileSerializer
    
    def get_queryset(self):
        # In a real app, verify request.user.role == 'admin' here
        return CreativeProfile.objects.filter(is_verified=False).order_by('-created_at')

@api_view(['POST'])
def admin_manage_creative(request, pk):
    """
    POST /api/admin/creative/<pk>/
    Body: { "action": "approve" } or { "action": "decline" }
    """
    profile = get_object_or_404(CreativeProfile, pk=pk)
    action = request.data.get('action')

    if action == 'approve':
        profile.is_verified = True
        profile.save()
        return Response({"message": "Profile approved successfully"}, status=200)
    
    elif action == 'decline':
        # Delete the profile (User stays, but they lose creative status)
        profile.delete()
        return Response({"message": "Profile declined and removed"}, status=200)

    return Response({"error": "Invalid action"}, status=400)
#chat
@api_view(['GET'])
def get_chat_messages(request, booking_id):
    chat = ChatMessage.objects.filter(booking_id=booking_id).order_by('created_at')
    data = [{"message": c.message, "isMe": c.sender_id == request.user.id} for c in chat]
    return Response(data)

@api_view(['POST'])
def send_chat_message(request, booking_id):
    message = request.data.get("message")
    ChatMessage.objects.create(
        booking_id=booking_id,
        sender=request.user,
        message=message
    )
    return Response({"status": "sent"})
