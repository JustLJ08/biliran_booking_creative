from django.contrib.auth import authenticate
from django.shortcuts import get_object_or_404
from rest_framework.views import APIView
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status, generics, filters, viewsets
from django.utils import timezone

from rest_framework.parsers import JSONParser, FormParser, MultiPartParser

from .utils import send_otp_email 
from .models import (
    User, Contract, IndustryCategory, SubCategory, CreativeProfile,
    Booking, Product, Order, ServicePackage, EmailOTP,
    UserInterest, UserPreferences, ChatMessage
)
from .serializers import (
    ContractSerializer, RegisterSerializer, IndustryCategorySerializer,
    SubCategorySerializer, CreativeProfileSerializer, BookingSerializer,
    ProductSerializer, OrderSerializer, ServicePackageSerializer,
    ChatMessageSerializer
)

# ==========================
# AUTHENTICATION VIEWS
# ==========================

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        import traceback
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            user = serializer.save()
            otp_obj, _ = EmailOTP.objects.get_or_create(user=user)
            code = otp_obj.generate_otp()
            send_otp_email(user.email, code)
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        except Exception as e:
            error_trace = traceback.format_exc()
            print("=== REGISTRATION ERROR ===")
            print(error_trace)
            return Response({"error": str(e), "trace": error_trace}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ✅ FIXED LOGIN VIEW (FINAL WORKING VERSION)
class LoginView(APIView):
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    def post(self, request):

        print("LOGIN DATA RECEIVED:", request.data)  # DEBUG

        username = request.data.get("username")
        password = request.data.get("password")

        if not username or not password:
            return Response(
                {"error": "Username and password are required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = authenticate(username=username, password=password)

        if user is None:
            return Response(
                {"error": "Invalid credentials"},
                status=status.HTTP_400_BAD_REQUEST
            )

        return Response(
            {
                "id": user.id,
                "username": user.username,
                "role": user.role,
                "token": "dummy-token-for-now",  # add JWT later
            },
            status=200
        )


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
# USER PREFERENCES VIEWS
# ==========================

@api_view(['GET'])
def check_preferences(request):
    user_id = request.query_params.get('user_id')
    
    if not user_id:
        return Response({"error": "User ID required"}, status=400)

    exists = UserPreferences.objects.filter(user_id=user_id).exists()
    return Response({"has_preferences": exists}, status=200)


@api_view(['POST'])
def save_preferences(request):
    try:
        user_id = request.data.get("user_id")
        categories = request.data.get("categories", [])
        sub_categories_map = request.data.get("subCategories", {})
        budget = request.data.get("budget")
        location = request.data.get("location")

        user = get_object_or_404(User, id=user_id)

        pref, _ = UserPreferences.objects.update_or_create(
            user=user,
            defaults={
                "categories": ", ".join(categories),
                "max_budget": budget,
                "location": location
            }
        )

        UserInterest.objects.filter(user=user).delete()

        for category in sub_categories_map.values():
            for sub_name in category:
                try:
                    sub_cat = SubCategory.objects.get(name=sub_name)
                    UserInterest.objects.create(user=user, sub_category=sub_cat)
                except SubCategory.DoesNotExist:
                    pass

        return Response({"success": True, "message": "Preferences saved successfully!"})

    except Exception as e:
        return Response({"success": False, "error": str(e)}, status=400)


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
# CHECK IF CREATIVE IS VERIFIED
# ==========================

@api_view(['GET'])
def check_creative_verified(request):
    user_id = request.query_params.get("user_id")

    try:
        profile = CreativeProfile.objects.get(user_id=user_id)
        return Response({
            "has_profile": True,
            "is_verified": profile.is_verified
        }, status=200)

    except CreativeProfile.DoesNotExist:
        return Response({
            "has_profile": False,
            "is_verified": False
        }, status=200)


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
        "creative.__user__last_name",
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
    serializer_class = ProductSerializer
    parser_classes = (MultiPartParser, FormParser)
    filter_backends = [filters.SearchFilter]
    search_fields = ["name"]

    def get_queryset(self):
        creative_id = self.request.query_params.get("creative_id")
        if creative_id:
            return Product.objects.filter(creative_id=creative_id)
        return Product.objects.all()

    def get_serializer_context(self):
        return {"request": self.request}

    def perform_create(self, serializer):
        serializer.save()


class ProductDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer

    def get_serializer_context(self):
        return {"request": self.request}


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

class CreateCreativeProfile(APIView):
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request):
        user_id = request.data.get("user")

        if CreativeProfile.objects.filter(user_id=user_id).exists():
            return Response({"message": "Profile already exists", "status": "exists"}, status=200)

        serializer = CreativeProfileSerializer(data=request.data, context={'request': request})

        if serializer.is_valid():
            serializer.save(user_id=user_id, is_verified=False)
            return Response(serializer.data, status=201)

        return Response(serializer.errors, status=400)


class CreativeProfileDetail(generics.RetrieveAPIView):
    serializer_class = CreativeProfileSerializer

    def get_serializer_context(self):
        return {'request': self.request}

    def get_object(self):
        user_id = self.request.query_params.get("user_id")
        return get_object_or_404(CreativeProfile, user_id=user_id)


# =========================================================
#  RECOMMENDATIONS
# =========================================================

@api_view(['POST'])
def save_user_interests(request):
    user_id = request.data.get('user_id')
    subcategory_ids = request.data.get('subcategory_ids', [])

    if not user_id:
        return Response({"error": "User ID required"}, status=400)

    try:
        UserInterest.objects.filter(user_id=user_id).delete()

        for sub_id in subcategory_ids:
            if SubCategory.objects.filter(id=sub_id).exists():
                UserInterest.objects.create(user_id=user_id, sub_category_id=sub_id)

        return Response({"message": "Interests saved successfully"}, status=200)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


@api_view(['GET'])
def recommended_creatives(request):
    user_id = request.query_params.get('user_id')

    if not user_id:
        return Response([], status=200)

    interested_sub_ids = UserInterest.objects.filter(user_id=user_id).values_list('sub_category_id', flat=True)

    if not interested_sub_ids:
        return Response([], status=200)

    creatives = CreativeProfile.objects.filter(sub_category_id__in=interested_sub_ids).exclude(user_id=user_id)
    serializer = CreativeProfileSerializer(creatives, many=True, context={'request': request})
    return Response(serializer.data, status=200)


# ==========================
# CONTRACT VIEWS
# ==========================

@api_view(['GET'])
def get_booking_contract(request, booking_id):
    try:
        booking = Booking.objects.get(id=booking_id)
    except Booking.DoesNotExist:
        return Response({"error": "Booking not found"}, status=404)

    contract, created = Contract.objects.get_or_create(booking=booking)
    
    if created:
        client_name = booking.client.username
        creative_name = booking.creative.user.username
        date = booking.booking_date
        price = booking.creative.hourly_rate 
        
        contract.body_text = f"""
CONTRACT OF SERVICE AGREEMENT

This Agreement is made between:
CLIENT: {client_name}
PROVIDER: {creative_name}

1. SERVICES
The Provider agrees to perform services on {date} as requested.

2. PAYMENT
The Client agrees to pay the rate of ₱{price} per hour/day.

3. CANCELLATION
Cancellations made less than 24 hours before the booking time may incur a fee.
"""
        contract.save()

    serializer = ContractSerializer(contract)
    return Response(serializer.data)


@api_view(['POST'])
def sign_contract(request, contract_id):
    try:
        contract = Contract.objects.get(id=contract_id)
    except Contract.DoesNotExist:
        return Response({"error": "Contract not found"}, status=404)

    role = request.data.get('role')
    
    if role == 'client':
        contract.is_client_signed = True
        contract.client_signed_at = timezone.now()
    elif role == 'creative':
        contract.is_creative_signed = True
        contract.creative_signed_at = timezone.now()
        
    contract.save()
    return Response({"message": "Contract signed successfully"})


# ==========================
# ADMIN VIEWS
# ==========================

class AdminPendingCreatives(generics.ListAPIView):
    serializer_class = CreativeProfileSerializer
    
    def get_queryset(self):
        return CreativeProfile.objects.filter(is_verified=False).order_by('-created_at')


@api_view(['POST'])
def admin_manage_creative(request, pk):
    profile = get_object_or_404(CreativeProfile, pk=pk)
    action = request.data.get('action')

    if action == 'approve':
        profile.is_verified = True
        profile.save()
        return Response({"message": "Profile approved successfully"}, status=200)
    
    elif action == 'decline':
        profile.delete()
        return Response({"message": "Profile declined and removed"}, status=200)

    return Response({"error": "Invalid action"}, status=400)


# ==========================
# CHAT / MESSAGING VIEWSET
# ==========================

from datetime import timedelta
from django.utils import timezone

def cleanup_old_messages():
    """Lazily deletes chat messages older than 30 days"""
    thirty_days_ago = timezone.now() - timedelta(days=30)
    ChatMessage.objects.filter(created_at__lt=thirty_days_ago).delete()

class ChatMessageViewSet(viewsets.ModelViewSet):
    queryset = ChatMessage.objects.all()
    serializer_class = ChatMessageSerializer

    def get_queryset(self):
        cleanup_old_messages() # Auto-delete old messages
        queryset = super().get_queryset()
        booking_id = self.kwargs.get('booking_id') or self.request.query_params.get('booking_id')
        
        if booking_id:
            queryset = queryset.filter(booking_id=booking_id).order_by('created_at')
        return queryset

    def perform_create(self, serializer):
        booking_id = self.kwargs.get('booking_id')

        if booking_id:
            serializer.save(booking_id=booking_id)
        else:
            serializer.save()


class ConversationMessagesView(APIView):
    """
    Aggregates chat messages across ALL bookings between a specific
    client and creative (provider). This ensures one chat thread per
    client-provider pair instead of per booking.

    GET  ?client_id=X&creative_user_id=Y  → all messages between them
    POST {client_id, creative_user_id, sender, message} → attach to latest booking
    """

    def _get_bookings(self, client_id, creative_user_id):
        """Return all bookings between the client and creative."""
        return Booking.objects.filter(
            client_id=client_id,
            creative__user_id=creative_user_id,
        ).order_by('-created_at')

    def get(self, request):
        cleanup_old_messages() # Auto-delete old messages
        client_id = request.query_params.get('client_id')
        creative_user_id = request.query_params.get('creative_user_id')

        if not client_id or not creative_user_id:
            return Response(
                {"error": "client_id and creative_user_id are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        bookings = self._get_bookings(client_id, creative_user_id)
        booking_ids = bookings.values_list('id', flat=True)

        messages = ChatMessage.objects.filter(
            booking_id__in=booking_ids
        ).order_by('created_at')

        serializer = ChatMessageSerializer(messages, many=True)
        return Response(serializer.data)

    def post(self, request):
        client_id = request.data.get('client_id')
        creative_user_id = request.data.get('creative_user_id')
        sender_id = request.data.get('sender')
        message_text = request.data.get('message')

        if not all([client_id, creative_user_id, sender_id, message_text]):
            return Response(
                {"error": "client_id, creative_user_id, sender, and message are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        bookings = self._get_bookings(client_id, creative_user_id)
        if not bookings.exists():
            return Response(
                {"error": "No bookings found between this client and creative"},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Attach message to the most recent booking
        latest_booking = bookings.first()

        chat_msg = ChatMessage.objects.create(
            booking=latest_booking,
            sender_id=sender_id,
            message=message_text,
        )

        serializer = ChatMessageSerializer(chat_msg)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class AdminBookingList(generics.ListAPIView):
    queryset = Booking.objects.all().order_by('-created_at')
    serializer_class = BookingSerializer


class AdminUpdateBooking(APIView):
    def patch(self, request, pk):
        booking = get_object_or_404(Booking, id=pk)
        status = request.data.get("status")
        if status not in ['pending','confirmed','completed','cancelled']:
            return Response({"error": "Invalid status"}, status=400)

        booking.status = status
        booking.save()
        return Response({"message":"Status updated"}, status=200)

