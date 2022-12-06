from django.contrib import admin
from django.urls import path, re_path, include, reverse_lazy
from rest_framework import routers
from podcasts.views import PodcastViewSet, GenreViewSet, EpisodeViewSet, UserViewSet, UserLogIn
from django.views.generic.base import RedirectView
from .views import privacy

router = routers.DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'podcasts', PodcastViewSet)
router.register(r'genres', GenreViewSet)
router.register(r'episodes', EpisodeViewSet)

urlpatterns = [
    path('privacy', privacy),
    path('admin/', admin.site.urls),
    path('api/v1/', include(router.urls)),
    path('api-user-login/', UserLogIn.as_view()),
    path('api-auth/', include('rest_framework.urls')),
    re_path(r'^$', RedirectView.as_view(url=reverse_lazy('api-root'), permanent=False)),
]


