import datetime
from .models import Podcast, Genre
from .serializers import PodcastSerializer, GenreSerializer
from .tasks import scrape_podcasts, stop_scraping
from rest_framework import viewsets, permissions, renderers
from rest_framework.pagination import PageNumberPagination
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import filters


class StandardResultsSetPagination(PageNumberPagination):
    page_size = 10


class PodcastViewSet(viewsets.ModelViewSet):
    queryset = Podcast.objects.all()
    serializer_class = PodcastSerializer
    search_fields = ['title']
    filter_backends = [filters.SearchFilter]
    permission_classes = [permissions.AllowAny]
    pagination_class = StandardResultsSetPagination

    @action(url_path='scrape', detail=False, renderer_classes=[renderers.StaticHTMLRenderer])
    def scrape(self, request, *args, **kwargs):
        scrape_podcasts.delay()
        now = datetime.datetime.now()
        html = "<html><body>" \
            "Scraping started" \
            "<br />" \
            f"It is now {now}." \
            "<br />" \
            "<button onclick='history.back()'>Go Back</button>" \
            "</body></html>"
        return Response(html)

    @action(url_path='stop', detail=False, renderer_classes=[renderers.StaticHTMLRenderer])
    def stop(self, request, *args, **kwargs):
        stop_scraping.delay()
        now = datetime.datetime.now()
        html = "<html><body>" \
            "Scraping stopped" \
            "<br />" \
            f"It is now {now}." \
            "<br />" \
            "<button onclick='history.back()'>Go Back</button>" \
            "</body></html>"
        return Response(html)


class GenreViewSet(viewsets.ModelViewSet):
    queryset = Genre.objects.all()
    serializer_class = GenreSerializer
    search_fields = ['title']
    filter_backends = [filters.SearchFilter]
    permission_classes = [permissions.AllowAny]
    pagination_class = StandardResultsSetPagination
