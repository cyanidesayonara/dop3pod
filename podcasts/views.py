from .models import Podcast
from .serializers import PodcastSerializer
from .tasks import scrape_podcasts
from rest_framework import viewsets, permissions
from rest_framework.response import Response


class PodcastViewSet(viewsets.ModelViewSet):
    queryset = Podcast.objects.all()
    serializer_class = PodcastSerializer
    permission_classes = [permissions.AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = Podcast.objects.all()
        serializer = PodcastSerializer(queryset, many=True)
        scrape_podcasts.delay()
        return Response(serializer.data)
