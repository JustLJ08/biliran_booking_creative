from django.contrib.auth import authenticate
from django.shortcuts import get_object_or_404
from rest_framework.views import APIView
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status, generics, filters
from .models import (
    User,
    IndustryCategory,
    SubCategory,
    CreativeProfile,
    Booking,
    Product,
    Order,
    ServicePackage,
    UserInterest, # Ensure this is imported
)
from .serializers import (
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
            serializer.save(user_id=user_id, is_verified=True)
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