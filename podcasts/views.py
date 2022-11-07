import datetime
import logging
from rest_framework import filters, viewsets, permissions
from rest_framework.pagination import PageNumberPagination
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import render, get_object_or_404
from .models import Podcast, Genre, Episode, get_episodes
from .serializers import PodcastSerializer, GenreSerializer, EpisodeSerializer
from .tasks import scrape_podcasts, stop_scraping

logger = logging.getLogger(__name__)


class StandardResultsSetPagination(PageNumberPagination):
    page_size = 10


class PodcastViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Podcast.objects.all()
    serializer_class = PodcastSerializer
    search_fields = ['title']
    filter_backends = [filters.SearchFilter]
    permission_classes = [permissions.AllowAny]
    pagination_class = StandardResultsSetPagination
    ordering_fields = ['view_count', 'title', 'discriminate']

    def retrieve(self, request, *args, **kwargs):
        obj = self.get_object()
        obj.view_count = obj.view_count + 1
        obj.save(update_fields=("view_count", ))
        return super().retrieve(request, *args, **kwargs)

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
