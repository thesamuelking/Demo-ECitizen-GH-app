from django.conf import settings
from django.db import models


class CitizenApplication(models.Model):
    class Status(models.TextChoices):
        DRAFT = 'draft', 'Draft'
        PENDING = 'pending', 'Pending'
        PROCESSING = 'processing', 'Processing'
        APPROVED = 'approved', 'Approved'
        REJECTED = 'rejected', 'Rejected'
        READY = 'ready', 'Ready'

    id = models.CharField(max_length=64, primary_key=True)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='applications')
    service = models.CharField(max_length=200)
    service_id = models.CharField(max_length=100, blank=True)
    service_department = models.CharField(max_length=100, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.DRAFT)
    date = models.CharField(max_length=40)
    ref_no = models.CharField(max_length=80)
    form_data = models.JSONField(default=dict)
    documents = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ('-updated_at',)


class ApplicationNotification(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='application_notifications')
    title = models.CharField(max_length=160)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ('-created_at',)


class ApplicationDocument(models.Model):
    application = models.ForeignKey(
        CitizenApplication, on_delete=models.CASCADE, related_name='uploaded_documents'
    )
    name = models.CharField(max_length=255)
    file = models.FileField(upload_to='application_documents/')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ('name',)
