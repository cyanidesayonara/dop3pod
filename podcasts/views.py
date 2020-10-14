from .models import Podcast
from .serializers import PodcastSerializer
from rest_framework import viewsets, permissions


class PodcastViewSet(viewsets.ModelViewSet):
    queryset = Podcast.objects.all()
    serializer_class = PodcastSerializer
    permission_classes = [permissions.AllowAny]
