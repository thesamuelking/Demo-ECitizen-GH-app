from django.contrib.auth import authenticate
from rest_framework import generics, status, views
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.serializers import TokenRefreshSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from .models import CitizenUser
from .serializers import RegisterSerializer, UserSerializer, VerifyAccountSerializer


def normalized_phone(value):
    return ''.join(character for character in value if character.isdigit())


def auth_response(user):
    refresh = RefreshToken.for_user(user)
    return {'user': UserSerializer(user).data, 'access_token': str(refresh.access_token), 'refresh_token': str(refresh)}


class RegisterView(views.APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response(auth_response(serializer.save()), status=status.HTTP_201_CREATED)


class LoginView(views.APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        user = authenticate(email=request.data.get('email'), password=request.data.get('password'))
        if user is None:
            return Response({'message': 'Incorrect email or password.'}, status=status.HTTP_401_UNAUTHORIZED)
        return Response(auth_response(user))


class ResetPasswordView(views.APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        phone = normalized_phone(request.data.get('phone', ''))
        new_password = request.data.get('new_password', '')

        if len(new_password) < 8:
            return Response({'message': 'Password must be at least 8 characters.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = CitizenUser.objects.get(email__iexact=email)
        except CitizenUser.DoesNotExist:
            return Response({'message': 'Email and phone number do not match an account.'}, status=status.HTTP_400_BAD_REQUEST)

        if normalized_phone(user.phone) != phone:
            return Response({'message': 'Email and phone number do not match an account.'}, status=status.HTTP_400_BAD_REQUEST)
        if user.check_password(new_password):
            return Response({'message': 'Choose a new password different from your old password.'}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(new_password)
        user.save(update_fields=['password'])
        return Response({'message': 'Password reset successfully.'})


class AdminLoginView(views.APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        user = authenticate(email=request.data.get('email'), password=request.data.get('password'))
        if user is None or not user.is_staff or not user.email.lower().endswith('@ecitizengh.com'):
            return Response({'message': 'Use an authorized government staff account.'}, status=status.HTTP_401_UNAUTHORIZED)
        department = request.data.get('service_department', '')
        valid_departments = {value for value, _ in CitizenUser.SERVICE_DEPARTMENTS}
        if department not in valid_departments:
            return Response({'message': 'Choose a valid service department.'}, status=status.HTTP_400_BAD_REQUEST)
        if user.service_department and user.service_department != department:
            return Response({'message': 'This staff account is assigned to another service department.'}, status=status.HTTP_403_FORBIDDEN)
        if not user.service_department:
            user.service_department = department
            user.save(update_fields=['service_department'])
        return Response(auth_response(user))


class GhanaCardLoginView(views.APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        try:
            user = CitizenUser.objects.get(ghanacard_number__iexact=request.data.get('ghanacard_number', ''))
        except CitizenUser.DoesNotExist:
            return Response({'message': 'No account was found for that Ghana Card number.'}, status=status.HTTP_401_UNAUTHORIZED)
        return Response(auth_response(user))


class RefreshView(views.APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        serializer = TokenRefreshSerializer(data={'refresh': request.data.get('refresh_token')})
        serializer.is_valid(raise_exception=True)
        return Response({'access_token': serializer.validated_data['access']})


class MeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    def get_object(self):
        return self.request.user


class VerifyAccountView(views.APIView):
    def post(self, request):
        serializer = VerifyAccountSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        full_name = ' '.join(serializer.validated_data['full_name'].split()).casefold()
        user = request.user
        if full_name != ' '.join(user.full_name.split()).casefold():
            return Response({'message': 'Full name does not match your account.'}, status=status.HTTP_400_BAD_REQUEST)

        ghanacard_number = serializer.validated_data['ghanacard_number']
        if CitizenUser.objects.filter(ghanacard_number__iexact=ghanacard_number).exclude(pk=user.pk).exists():
            return Response({'message': 'That Ghana Card number is already linked to another account.'}, status=status.HTTP_400_BAD_REQUEST)

        user.ghanacard_number = ghanacard_number
        user.is_verified = True
        user.save(update_fields=['ghanacard_number', 'is_verified'])
        return Response(UserSerializer(user).data)


class ChangePasswordView(views.APIView):
    def post(self, request):
        if not request.user.check_password(request.data.get('current_password', '')):
            return Response({'message': 'Current password is incorrect.'}, status=status.HTTP_400_BAD_REQUEST)
        request.user.set_password(request.data.get('new_password', ''))
        request.user.save(update_fields=['password'])
        return Response(status=status.HTTP_204_NO_CONTENT)


class LogoutView(views.APIView):
    def post(self, request):
        try:
            RefreshToken(request.data.get('refresh_token', '')).blacklist()
        except Exception:
            pass
        return Response(status=status.HTTP_204_NO_CONTENT)
