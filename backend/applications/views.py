from rest_framework import mixins, permissions, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import ApplicationDocument, ApplicationNotification, CitizenApplication
from .serializers import (AdminApplicationSerializer, ApplicationDocumentSerializer,
                           ApplicationSerializer, NotificationSerializer)


class ApplicationViewSet(viewsets.ModelViewSet):
    serializer_class = ApplicationSerializer

    def get_queryset(self):
        return CitizenApplication.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class ApplicationDocumentViewSet(viewsets.ModelViewSet):
    serializer_class = ApplicationDocumentSerializer
    http_method_names = ['post', 'head', 'options']

    def get_queryset(self):
        return ApplicationDocument.objects.filter(application__user=self.request.user)

    def perform_create(self, serializer):
        application_id = self.request.data.get('application')
        try:
            application = CitizenApplication.objects.get(
                id=application_id, user=self.request.user
            )
        except CitizenApplication.DoesNotExist:
            from rest_framework.exceptions import ValidationError
            raise ValidationError({'application': 'Application not found.'})
        serializer.save(application=application)


class AdminApplicationViewSet(viewsets.ModelViewSet):
    serializer_class = AdminApplicationSerializer
    permission_classes = [permissions.IsAdminUser]
    http_method_names = ['get', 'patch', 'head', 'options']

    def get_queryset(self):
        queryset = CitizenApplication.objects.select_related('user').prefetch_related(
            'uploaded_documents'
        ).all()
        service = self.request.query_params.get('service')
        status_filter = self.request.query_params.get('status')
        if service:
            queryset = queryset.filter(service_department=service)
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        return queryset

    def perform_update(self, serializer):
        previous_status = serializer.instance.status
        application = serializer.save()
        if previous_status != application.status:
            label = application.get_status_display()
            if application.status == CitizenApplication.Status.READY:
                title = 'Application ready for pickup'
                message = (
                    f'Your "{application.service}" application is ready for pickup '
                    'exactly one week at 9:00am.'
                )
            else:
                title = f'Application {label}'
                message = (
                    f'Your {application.service} application '
                    f'({application.ref_no}) is now {label.lower()}.'
                )
            ApplicationNotification.objects.create(
                user=application.user,
                title=title,
                message=message,
            )

    @action(detail=False, methods=['get'], url_path='summary')
    def summary(self, request):
        queryset = self.get_queryset()
        counts = {status: queryset.filter(status=status).count() for status, _ in CitizenApplication.Status.choices}
        return Response({'total': queryset.count(), 'counts': counts})


class NotificationViewSet(
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    mixins.UpdateModelMixin,
    mixins.DestroyModelMixin,
    viewsets.GenericViewSet,
):
    serializer_class = NotificationSerializer
    http_method_names = ['get', 'patch', 'delete', 'head', 'options']

    def get_queryset(self):
        return ApplicationNotification.objects.filter(user=self.request.user)
