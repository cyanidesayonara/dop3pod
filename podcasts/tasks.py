import os
import logging
from celery import Celery, shared_task
from scrapy.crawler import CrawlerProcess
from scrapy.utils.project import get_project_settings
from willy.willy.spiders.scraper import WillyTheSpider

logger = logging.getLogger(__name__)
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dop3pod.settings')


@shared_task(name="scrape_podcasts_task")
def scrape_podcasts():
    process = CrawlerProcess(get_project_settings())
    process.crawl(WillyTheSpider)
    process.start()


@shared_task(name="stop_scraping_task")
def stop_scraping():
    app = Celery('dop3pod')
    app.config_from_object('django.conf:settings', namespace='CELERY')
    for worker, tasks in app.control.inspect().active().items():
        for task in tasks:
            try:
                task_id = task['id']
                name = task['name']
                if task_id and name == 'scrape_podcasts_task':
                    app.control.revoke(task_id, terminate=True, signal='SIGKILL')
                    logger.info(f'Stopped scraping task id: {task_id}')
            except KeyError as e:
                logger.error(f"Failed to stop scraping: {e}")
