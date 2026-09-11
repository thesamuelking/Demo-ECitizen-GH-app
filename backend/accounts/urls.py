from django.urls import path
from .views import AdminLoginView, ChangePasswordView, GhanaCardLoginView, LoginView, LogoutView, MeView, RefreshView, RegisterView, ResetPasswordView, VerifyAccountView

urlpatterns = [
    path('register', RegisterView.as_view()), path('login', LoginView.as_view()), path('reset-password', ResetPasswordView.as_view()), path('admin-login', AdminLoginView.as_view()),
    path('login/ghana-card', GhanaCardLoginView.as_view()), path('refresh', RefreshView.as_view()),
    path('me', MeView.as_view()), path('verify-account', VerifyAccountView.as_view()),
    path('change-password', ChangePasswordView.as_view()), path('logout', LogoutView.as_view()),
]
