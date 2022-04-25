import logging
from celery import shared_task
from scrapy.crawler import CrawlerProcess
from scrapy.utils.project import get_project_settings
from willy.willy.spiders.scraper import WillyTheSpider

logger = logging.getLogger(__name__)


@shared_task(name="scrape_podcasts_task")
def scrape_podcasts():
    process = CrawlerProcess(get_project_settings())
    process.crawl(WillyTheSpider)
    process.start()
