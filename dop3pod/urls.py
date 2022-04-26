from django.contrib import admin
from django.urls import include, path
from podcasts.views import PodcastViewSet, GenreViewSet
from rest_framework import routers
from .views import privacy


# Routers provide an easy way of automatically determining the URL conf.
router = routers.DefaultRouter()
router.register(r'podcasts', PodcastViewSet)
router.register(r'genres', GenreViewSet)

urlpatterns = [
    path('', include(router.urls)),
    # path('admin/', admin.site.urls),
    path('api-auth/', include('rest_framework.urls')),
    path('privacy', privacy)
]
