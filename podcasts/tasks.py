from django.db import transaction
from string import ascii_lowercase
from fake_useragent import UserAgent
import requests
import random
import logging
from celery import shared_task
from .models import Podcast

logger = logging.getLogger(__name__)
ua = UserAgent()
headers = {
    'User-Agent': str(ua.random)
}


@shared_task(name="scrape_podcasts_task")
def scrape_podcasts():
    url = 'https://itunes.apple.com/search?media=podcast&entity=podcast&attribute=titleTerm&limit=200&term='
    url = url + random.choice(ascii_lowercase) + random.choice(ascii_lowercase)
    try:
        logger.error('scraping %s', url)
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        data = response.json()
        results = data['results']
        update_or_save_results(results)
    except Exception as e:
        logger.error('Exception: %s', e)


def update_or_save_results(results):
    for result in results:
        try:
            title = result['collectionName']
            feed_url = result['feedUrl']
            artwork_url = result['artworkUrl600']
            response = requests.get(feed_url, headers=headers, timeout=10)
            response.raise_for_status()
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
        except KeyError as e:
            logger.error('Missing data: %s', e)
