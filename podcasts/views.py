from django.http import JsonResponse
from fake_useragent import UserAgent
from django.db import transaction
import requests
import logging

from .models import Podcast

logger = logging.getLogger(__name__)
ua = UserAgent()


def start(request):
    scrape_podcasts()
    podcasts = Podcast.objects.all()
    data = list(podcasts.values())
    return JsonResponse(data, safe=False)


def scrape_podcasts():
    try:
        print(Podcast.objects.all())
        return
    except Exception as e:
        logger.error(e)

    headers = {
        'User-Agent': str(ua.random)
    }
    logger.info('scraping')
    url = 'https://itunes.apple.com/search?media=podcast&entity=podcast&attribute=titleTerm&limit=200&term='
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        data = response.json()
        results = data['results']
        for result in results:
            title = result['collectionName']
            feed_url = result['feedUrl']
            artwork_url = result['artworkUrl600']

            # TODO try to get episodes before creating podcast
            podcast, created = Podcast.objects.select_related(None).select_for_update().update_or_create(
                feed_url=feed_url,
                defaults={
                    'title': title,
                    'feed_url': feed_url,
                    'artwork_url': artwork_url
                }
            )
            with transaction.atomic():
                if created:
                    logger.info('created podcast %s %s', title, feed_url)
                else:
                    logger.info('updated podcast %s %s', title, feed_url)

    except (KeyError, IndexError) as e:
        logger.error("Missing data: %s", e)
