from django.contrib.auth import authenticate
from django.shortcuts import get_object_or_404
from rest_framework.views import APIView
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status, generics, filters, viewsets
from django.utils import timezone
from django.views.decorators.cache import cache_page
from django.utils.decorators import method_decorator

from rest_framework.parsers import JSONParser, FormParser, MultiPartParser

from .utils import send_otp_email 
from .models import (
    User, Contract, IndustryCategory, SubCategory, CreativeProfile,
    Booking, Product, Order, ServicePackage, EmailOTP,
    UserInterest, UserPreferences, ChatMessage, SearchHistory
)
from .serializers import (
    ContractSerializer, RegisterSerializer, IndustryCategorySerializer,
    SubCategorySerializer, CreativeProfileSerializer, BookingSerializer,
    ProductSerializer, OrderSerializer, ServicePackageSerializer,
    ChatMessageSerializer, SearchHistorySerializer
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

class UploadBookingProof(APIView):
    parser_classes = (MultiPartParser, FormParser)

    def put(self, request, pk):
        try:
            booking = Booking.objects.get(pk=pk)
            
            if 'payment_proof' in request.FILES:
                booking.payment_proof = request.FILES['payment_proof']
                booking.status = 'deposit_uploaded'
                booking.save()
                
                serializer = BookingSerializer(booking, context={'request': request})
                return Response(serializer.data, status=status.HTTP_200_OK)
            else:
                return Response({'error': 'No image provided.'}, status=status.HTTP_400_BAD_REQUEST)
                
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found.'}, status=status.HTTP_404_NOT_FOUND)


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
        
        # Prevent ordering if not enough stock
        if product.stock < quantity:
            from rest_framework.exceptions import ValidationError
            raise ValidationError({"error": "Not enough stock available"})

        # Decrement stock
        product.stock -= quantity
        product.save()

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


class ServicePackageDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = ServicePackage.objects.all()
    serializer_class = ServicePackageSerializer


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
@cache_page(300)  # Cache recommendations for 5 minutes
def recommended_creatives(request):
    """Content-based recommendation combining 3 signals:
    1. Explicit preferences (UserInterest) — highest weight
    2. Search behavior (SearchHistory) — medium weight
    3. Booking history (Booking) — fallback weight
    """
    user_id = request.query_params.get('user_id')

    if not user_id:
        return Response([], status=200)

    # Signal 1: Explicit preferences (user-selected subcategories)
    interest_sub_ids = set(
        UserInterest.objects.filter(user_id=user_id)
        .values_list('sub_category_id', flat=True)
    )

    # Signal 2: Search behavior (subcategories from recent search taps)
    search_sub_ids = set(
        SearchHistory.objects.filter(user_id=user_id, sub_category__isnull=False)
        .values_list('sub_category_id', flat=True)
    )

    # Signal 3: Booking history (subcategories of previously booked creatives)
    booking_sub_ids = set(
        Booking.objects.filter(client_id=user_id)
        .values_list('creative__sub_category_id', flat=True)
    )

    # Merge all signals (union)
    all_sub_ids = interest_sub_ids | search_sub_ids | booking_sub_ids

    if not all_sub_ids:
        return Response([], status=200)

    # Fetch matching verified creatives, excluding the user themselves
    creatives = (
        CreativeProfile.objects
        .filter(sub_category_id__in=all_sub_ids, is_verified=True)
        .exclude(user_id=user_id)
        .select_related('user', 'sub_category', 'sub_category__industry')
        .distinct()
    )

    # Rank: creatives matching more signals appear first
    def rank_score(creative):
        score = 0
        sid = creative.sub_category_id
        if sid in interest_sub_ids:
            score += 3  # Highest weight
        if sid in search_sub_ids:
            score += 2  # Medium weight
        if sid in booking_sub_ids:
            score += 1  # Fallback weight
        return score

    ranked = sorted(creatives, key=rank_score, reverse=True)

    serializer = CreativeProfileSerializer(ranked, many=True, context={'request': request})
    return Response(serializer.data, status=200)


# =========================================================
#  SEARCH HISTORY
# =========================================================

class SearchHistoryView(APIView):
    """Manages per-user search history for recent searches & recommendation signals.
    GET    ?user_id=X              → 20 most recent searches (distinct queries)
    POST   {user_id, query, sub_category_id?} → record a search
    DELETE ?user_id=X              → clear all search history
    """

    def get(self, request):
        user_id = request.query_params.get('user_id')
        if not user_id:
            return Response({"error": "user_id is required"}, status=status.HTTP_400_BAD_REQUEST)

        entries = SearchHistory.objects.filter(user_id=user_id).order_by('-created_at')[:20]
        serializer = SearchHistorySerializer(entries, many=True)
        return Response(serializer.data)

    def post(self, request):
        user_id = request.data.get('user_id')
        query_text = request.data.get('query', '').strip()
        sub_category_id = request.data.get('sub_category_id')

        if not user_id or not query_text:
            return Response(
                {"error": "user_id and query are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Avoid duplicate consecutive identical queries
        latest = SearchHistory.objects.filter(user_id=user_id).first()
        if latest and latest.query.lower() == query_text.lower():
            return Response({"message": "Duplicate skipped"}, status=200)

        SearchHistory.objects.create(
            user_id=user_id,
            query=query_text,
            sub_category_id=sub_category_id if sub_category_id else None,
        )
        return Response({"message": "Search recorded"}, status=status.HTTP_201_CREATED)

    def delete(self, request):
        user_id = request.query_params.get('user_id')
        if not user_id:
            return Response({"error": "user_id is required"}, status=status.HTTP_400_BAD_REQUEST)

        count, _ = SearchHistory.objects.filter(user_id=user_id).delete()
        return Response({"message": f"Cleared {count} entries"}, status=200)


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

        cleanup_old_messages() # Auto-delete old messages on post too

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


# ==========================
# REPORTS VIEWS
# ==========================

class AdminReportsView(APIView):
    """Platform-wide reports for admin dashboard."""

    @method_decorator(cache_page(600))  # Cache admin reports for 10 minutes
    def get(self, request):
        from django.db.models import Sum, Count, F, Value, DecimalField
        from django.db.models.functions import Coalesce, TruncMonth
        from datetime import datetime
        from dateutil.relativedelta import relativedelta

        now = timezone.now()
        six_months_ago = now - relativedelta(months=6)
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

        # Basic counts
        total_bookings = Booking.objects.count()
        bookings_this_month = Booking.objects.filter(created_at__gte=month_start).count()

        # Completed bookings revenue
        completed_bookings = Booking.objects.filter(status='completed')
        booking_revenue = 0.0
        for b in completed_bookings:
            if b.package and b.package.price:
                booking_revenue += float(b.package.price)
            else:
                booking_revenue += float(b.creative.hourly_rate)

        # Delivered orders revenue
        delivered_orders = Order.objects.filter(status='delivered')
        order_revenue = float(delivered_orders.aggregate(
            total=Coalesce(Sum('total_price'), Value(0), output_field=DecimalField())
        )['total'])

        total_revenue = booking_revenue + order_revenue
        total_sales = completed_bookings.count() + delivered_orders.count()

        # Revenue by category (industry)
        category_map = {}
        for b in completed_bookings.select_related('creative__sub_category__industry'):
            industry = b.creative.sub_category.industry.name
            price = float(b.package.price) if b.package and b.package.price else float(b.creative.hourly_rate)
            category_map[industry] = category_map.get(industry, 0) + price
        revenue_by_category = [{'category': k, 'revenue': v} for k, v in sorted(category_map.items(), key=lambda x: -x[1])]

        # Monthly trend (last 6 months)
        monthly_trend = []
        for i in range(5, -1, -1):
            m = now - relativedelta(months=i)
            m_start = m.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            m_end = (m_start + relativedelta(months=1))
            month_bookings = Booking.objects.filter(status='completed', created_at__gte=m_start, created_at__lt=m_end)
            month_rev = 0.0
            for b in month_bookings:
                if b.package and b.package.price:
                    month_rev += float(b.package.price)
                else:
                    month_rev += float(b.creative.hourly_rate)
            month_orders = Order.objects.filter(status='delivered', created_at__gte=m_start, created_at__lt=m_end)
            month_order_rev = float(month_orders.aggregate(
                total=Coalesce(Sum('total_price'), Value(0), output_field=DecimalField())
            )['total'])
            monthly_trend.append({
                'month': m_start.strftime('%Y-%m'),
                'revenue': month_rev + month_order_rev,
                'count': month_bookings.count() + month_orders.count(),
            })

        # Top 5 providers by revenue
        provider_map = {}
        for b in completed_bookings.select_related('creative__user'):
            name = f"{b.creative.user.first_name} {b.creative.user.last_name}"
            price = float(b.package.price) if b.package and b.package.price else float(b.creative.hourly_rate)
            if name not in provider_map:
                provider_map[name] = {'revenue': 0, 'bookings': 0}
            provider_map[name]['revenue'] += price
            provider_map[name]['bookings'] += 1
        top_providers = sorted(
            [{'name': k, 'revenue': v['revenue'], 'bookings': v['bookings']} for k, v in provider_map.items()],
            key=lambda x: -x['revenue']
        )[:5]

        return Response({
            'total_bookings': total_bookings,
            'bookings_this_month': bookings_this_month,
            'total_revenue': total_revenue,
            'total_sales': total_sales,
            'revenue_by_category': revenue_by_category,
            'monthly_trend': monthly_trend,
            'top_providers': top_providers,
        })


class ProviderReportsView(APIView):
    """Per-provider reports for provider dashboard."""

    def get(self, request):
        from django.db.models import Sum, Value, DecimalField
        from django.db.models.functions import Coalesce
        from dateutil.relativedelta import relativedelta

        user_id = request.query_params.get('user_id')
        if not user_id:
            return Response({'error': 'user_id is required'}, status=status.HTTP_400_BAD_REQUEST)

        now = timezone.now()

        try:
            profile = CreativeProfile.objects.get(user_id=user_id)
        except CreativeProfile.DoesNotExist:
            return Response({'error': 'Creative profile not found'}, status=status.HTTP_404_NOT_FOUND)

        # Booking revenue
        completed = Booking.objects.filter(creative=profile, status='completed')
        booking_revenue = 0.0
        for b in completed:
            if b.package and b.package.price:
                booking_revenue += float(b.package.price)
            else:
                booking_revenue += float(profile.hourly_rate)

        # Product revenue
        delivered = Order.objects.filter(product__creative=profile, status='delivered')
        product_revenue = float(delivered.aggregate(
            total=Coalesce(Sum('total_price'), Value(0), output_field=DecimalField())
        )['total'])

        total_revenue = booking_revenue + product_revenue
        total_sales = completed.count() + delivered.count()

        # Monthly trend (last 6 months)
        monthly_trend = []
        for i in range(5, -1, -1):
            m = now - relativedelta(months=i)
            m_start = m.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            m_end = m_start + relativedelta(months=1)
            mb = Booking.objects.filter(creative=profile, status='completed', created_at__gte=m_start, created_at__lt=m_end)
            rev = 0.0
            for b in mb:
                if b.package and b.package.price:
                    rev += float(b.package.price)
                else:
                    rev += float(profile.hourly_rate)
            mo = Order.objects.filter(product__creative=profile, status='delivered', created_at__gte=m_start, created_at__lt=m_end)
            orev = float(mo.aggregate(
                total=Coalesce(Sum('total_price'), Value(0), output_field=DecimalField())
            )['total'])
            monthly_trend.append({
                'month': m_start.strftime('%Y-%m'),
                'revenue': rev + orev,
            })

        # Conversion rate
        total_bookings = Booking.objects.filter(creative=profile).count()
        successful = Booking.objects.filter(creative=profile, status__in=['confirmed', 'completed']).count()
        conversion_rate = round((successful / total_bookings * 100), 1) if total_bookings > 0 else 0.0

        return Response({
            'total_revenue': total_revenue,
            'total_sales': total_sales,
            'booking_revenue': booking_revenue,
            'product_revenue': product_revenue,
            'monthly_trend': monthly_trend,
            'conversion_rate': conversion_rate,
        })


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

