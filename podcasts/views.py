import datetime
import logging
from rest_framework import filters, viewsets, permissions
from rest_framework.pagination import PageNumberPagination
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.authentication import SessionAuthentication, TokenAuthentication
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.authtoken.models import Token
from django.shortcuts import render, get_object_or_404
from .models import Podcast, Genre, Episode, get_episodes, User
from .serializers import PodcastSerializer, GenreSerializer, EpisodeSerializer, UserSerializer
from .tasks import scrape_podcasts, stop_scraping

logger = logging.getLogger(__name__)


class StandardResultsSetPagination(PageNumberPagination):
    page_size = 10


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    authentication_classes = [SessionAuthentication, TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]


class UserLogIn(ObtainAuthToken):
    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data,
                                           context={'request': request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']
        token = Token.objects.get(user=user)
        return Response({
            'token': token.key,
            'id': user.pk,
            'username': user.username
        })


class PodcastViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Podcast.objects.all()
    serializer_class = PodcastSerializer
    search_fields = ['title']
    filter_backends = [filters.SearchFilter]
    permission_classes = [permissions.AllowAny]
    pagination_class = StandardResultsSetPagination
    ordering_fields = ['view_count', 'title', 'discriminate']

    @staticmethod
    @action(url_path='scrape', detail=False)
    def scrape(request):
        scrape_podcasts.delay()
        now = datetime.datetime.now()
        return render(request, 'scraping.html', {'now': now, 'action': 'started'})

    @staticmethod
    @action(url_path='stop', detail=False)
    def stop(request):
        stop_scraping.delay()
        now = datetime.datetime.now()
        return render(request, 'scraping.html', {'now': now, 'action': 'stopped'})

    @staticmethod
    @action(url_path='episodes', detail=True, serializer_class=EpisodeSerializer)
    def get_episodes(request, pk=None):
        podcast = get_object_or_404(Podcast, pk=pk)
        podcast.view_count = podcast.view_count + 1
        podcast.save(update_fields=("view_count", ))
        episodes = get_episodes(podcast)
        serializer = EpisodeSerializer(episodes, many=True, context={'request': request})
        return Response(serializer.data)


class GenreViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Genre.objects.all()
    serializer_class = GenreSerializer
    search_fields = ['title']
    filter_backends = [filters.SearchFilter]
    permission_classes = [permissions.AllowAny]
    pagination_class = StandardResultsSetPagination


class EpisodeViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Episode.objects.all()
    serializer_class = EpisodeSerializer
    search_fields = ['title']
    filter_backends = [filters.SearchFilter]
    permission_classes = [permissions.AllowAny]
    pagination_class = StandardResultsSetPagination
