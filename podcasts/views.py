from django.http import JsonResponse
import logging
from .models import Podcast
from .tasks import scrape_podcasts

logger = logging.getLogger(__name__)


def index(request):
    scrape_podcasts.delay()
    podcasts = Podcast.objects.all()
    data = list(podcasts.values())
    return JsonResponse(data, safe=False)
