from django.urls import include, path
from rest_framework.routers import DefaultRouter
from .views import (AdminApplicationViewSet, ApplicationDocumentViewSet,
					ApplicationViewSet, NotificationViewSet)

router = DefaultRouter()
router.register('', ApplicationViewSet, basename='application')
admin_router = DefaultRouter()
admin_router.register('applications', AdminApplicationViewSet, basename='admin-application')
notification_router = DefaultRouter()
notification_router.register('notifications', NotificationViewSet, basename='notification')
document_router = DefaultRouter()
document_router.register('documents', ApplicationDocumentViewSet, basename='document')
urlpatterns = [
	path('admin/', include(admin_router.urls)),
	path('notifications/', NotificationViewSet.as_view({'get': 'list'}), name='notification-list'),
	path('notifications/<int:pk>/', NotificationViewSet.as_view({'delete': 'destroy'}), name='notification-detail'),
	path('documents/', ApplicationDocumentViewSet.as_view({'post': 'create'}), name='document-list'),
	path('', include(router.urls)),
]
