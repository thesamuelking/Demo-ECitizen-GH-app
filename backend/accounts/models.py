import uuid
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models


class CitizenUserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email is required.')
        user = self.model(email=self.normalize_email(email), **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)


class CitizenUser(AbstractBaseUser, PermissionsMixin):
    SERVICE_DEPARTMENTS = (
        ('Identity & Personal Documents', 'Identity & Personal Documents'),
        ("Transport & Driver's Services (DVLA)", "Transport & Driver's Services (DVLA)"),
        ('Taxes & Payments', 'Taxes & Payments'),
        ('Health & Insurance', 'Health & Insurance'),
        ('Social Security', 'Social Security'),
        ('Business & Company Services', 'Business & Company Services'),
        ('Safety & Justice', 'Safety & Justice'),
        ('Utilities & Assembly', 'Utilities & Assembly'),
    )
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=160)
    phone = models.CharField(max_length=30)
    ghanacard_number = models.CharField(max_length=30, unique=True, blank=True, null=True)
    profile_photo = models.TextField(blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    service_department = models.CharField(
        max_length=100, choices=SERVICE_DEPARTMENTS, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    objects = CitizenUserManager()
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['full_name', 'phone']
