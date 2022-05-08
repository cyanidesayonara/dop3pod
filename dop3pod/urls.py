from django.contrib import admin
from django.urls import include, path
from rest_framework import routers
from podcasts.views import PodcastViewSet, GenreViewSet, EpisodeViewSet
from .views import privacy

router = routers.DefaultRouter()
router.register(r'podcasts', PodcastViewSet)
router.register(r'genres', GenreViewSet)
router.register(r'episodes', EpisodeViewSet)

urlpatterns = [
    path('', include(router.urls)),
    # path('admin/', admin.site.urls),
    path('api-auth/', include('rest_framework.urls')),
    path('privacy', privacy)
]
