from rest_framework import serializers
from accounts.serializers import UserSerializer
from .models import ApplicationDocument, ApplicationNotification, CitizenApplication


class ApplicationSerializer(serializers.ModelSerializer):
    def validate_status(self, value):
        if value not in {
            CitizenApplication.Status.DRAFT,
            CitizenApplication.Status.PENDING,
        }:
            raise serializers.ValidationError('Citizens can only save drafts or submit applications.')
        return value

    class Meta:
        model = CitizenApplication
        fields = ('id', 'service', 'status', 'date', 'ref_no', 'service_id', 'service_department', 'form_data', 'documents')
        read_only_fields = ('user',)


class AdminApplicationSerializer(serializers.ModelSerializer):
    applicant = UserSerializer(source='user', read_only=True)
    documents = serializers.SerializerMethodField()

    def get_documents(self, application):
        request = self.context.get('request')
        return [
            {
                'name': document.name,
                'url': request.build_absolute_uri(document.file.url)
                if request else document.file.url,
            }
            for document in application.uploaded_documents.all()
        ]

    class Meta:
        model = CitizenApplication
        fields = ('id', 'service', 'status', 'date', 'ref_no', 'service_id', 'service_department', 'form_data', 'documents', 'applicant', 'created_at', 'updated_at')
        read_only_fields = ('id', 'service', 'date', 'ref_no', 'service_id', 'form_data', 'documents', 'applicant', 'created_at', 'updated_at')


class ApplicationDocumentSerializer(serializers.ModelSerializer):
    application = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = ApplicationDocument
        fields = ('id', 'application', 'name', 'file', 'uploaded_at')
        read_only_fields = ('id', 'application', 'uploaded_at')


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = ApplicationNotification
        fields = ('id', 'title', 'message', 'is_read', 'created_at')
        read_only_fields = ('id', 'title', 'message', 'created_at')
