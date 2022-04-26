import json

import scrapy
import requests
from string import Template
from django.db import transaction
from podcasts.models import Genre, Podcast
from willy.exceptions import WillyException
from lxml import html as lxml_html

UNWANTED_GENRE = "Podcasts"
HREF_SELECTOR = '@href'
PARSE_PODCASTS_SELECTOR = '//div[@id="genre-nav"]/div/ul/li/a'
PARSE_ALPHABETICAL_INDEX_SELECTOR = '//div[@id="genre-nav"]/div/ul/li/ul/li/a'
GENRE_SELECTOR = '//div[@id="genre-nav"]/div[@class="grid3-column"]/ul/li'
ALPHABETICAL_INDEX_GENRE_SELECTOR = '//div[@id="selectedgenre"]/ul/li/a'
PAGINATION_GENRE_SELECTOR = '//div[@id="selectedgenre"]/ul[2]/li/a'
SCRAPE_PODCAST_SELECTOR = '//div[@id="selectedcontent"]/div/ul/li/a[contains(@href, "id")]'
LIST_ITEM_SELECTOR = 'ul/li'
LINK_TEXT_SELECTOR = 'a/text()'
LINK_HREF_SELECTOR = 'a/@href'
DESCRIPTION_SELECTOR = "//section[@class='product-hero-desc__section']/div/p/text()"
COPYRIGHT_TEXT_SELECTOR = "//li[@class='tracklist-footer__item']/text()"
DEFAULT_COPYRIGHT_TEXT = "© All rights reserved"
ID_REGEX = r'/id(\d+)'
DONT_REDIRECT = {'dont_redirect': True}
ITUNES_LOOKUP_URL = Template("https://itunes.apple.com/lookup?id=$pod_id")
ITUNES_REVIEWS_URL = Template("https://itunes.apple.com/us/rss/customerreviews/id=$pod_id/json")


class WillyTheSpider(scrapy.Spider):
    name = 'willy'
    allowed_domains = ['itunes.apple.com']
    start_urls = ['https://itunes.apple.com/us/genre/podcasts/id26']

    def parse(self, response):
        self.create_or_update_genres(response)

        for link in response.xpath(PARSE_PODCASTS_SELECTOR):
            yield from self.create_or_update_podcasts(link)
        for link in response.xpath(PARSE_ALPHABETICAL_INDEX_SELECTOR):
            yield from self.create_or_update_podcasts(link)

    def create_or_update_genres(self, response):
        with transaction.atomic():
            for genre in response.xpath(GENRE_SELECTOR):
                supergenre = genre.xpath(LINK_TEXT_SELECTOR).extract_first()
                genre_id = genre.xpath(LINK_HREF_SELECTOR).re_first(ID_REGEX)
                supergenre, created = Genre.objects.select_related(None).select_for_update().update_or_create(
                    title=supergenre,
                    genre_id=genre_id,
                    supergenre=None,
                )

                if created:
                    self.log(f"Created supergenre {supergenre.title}")
                else:
                    self.log(f"Updated supergenre {supergenre.title}")

                for subgenre in genre.xpath(LIST_ITEM_SELECTOR):
                    title = subgenre.xpath(LINK_TEXT_SELECTOR).extract_first()
                    genre_id = subgenre.xpath(LINK_HREF_SELECTOR).re_first(ID_REGEX)
                    genre, created = Genre.objects.select_related(None).select_for_update().update_or_create(
                        title=title,
                        genre_id=genre_id,
                        supergenre=supergenre,
                    )

                    if created:
                        self.log(f"Created genre {genre.title}")
                    else:
                        self.log(f"Updated genre {genre.title}")

    def create_or_update_podcasts(self, link):
        url = link.xpath(HREF_SELECTOR).extract_first().split('?')[0]
        yield scrapy.Request(url, meta=DONT_REDIRECT, callback=self.parse_podcasts, dont_filter=True)
        yield scrapy.Request(url, meta=DONT_REDIRECT, callback=self.parse_alphabetical_index, dont_filter=True)

    def parse_alphabetical_index(self, response):
        """
        follows links to each pagination
        """

        for link in response.xpath(ALPHABETICAL_INDEX_GENRE_SELECTOR):
            extension = link.xpath(HREF_SELECTOR).extract_first().split('&')[-1]
            url = f'{response.url}?{extension}'
            yield scrapy.Request(url, meta=DONT_REDIRECT, callback=self.parse_pagination)

    def parse_pagination(self, response):
        """
        parses all podcasts on each page
        """

        for link in response.xpath(PAGINATION_GENRE_SELECTOR):
            extension = link.xpath(HREF_SELECTOR).extract_first().split('&')[-1].replace('#page', '')
            url = f'{response.url}&{extension}'
            yield scrapy.Request(url, meta=DONT_REDIRECT, callback=self.parse_podcasts)

    def parse_podcasts(self, response):
        """
        gets pod_id from podcast link
        uses itunes lookup to scrape podcast data by pod_id
        """

        for link in response.xpath(SCRAPE_PODCAST_SELECTOR):
            pod_id = link.xpath(HREF_SELECTOR).re_first(ID_REGEX)
            url = ITUNES_LOOKUP_URL.substitute(pod_id=pod_id)

            self.log(f"Scraping itunes lookup url {url}")

            yield scrapy.Request(url, meta=DONT_REDIRECT, callback=self.scrape_podcast)

    def scrape_podcast(self, response):
        try:
            json_response = response.json()
            data = json_response["results"][0]
            return self.build_podcast(data)
        except (IndexError, KeyError, WillyException) as e:
            self.log(f"Scraping failed: {e}")

    def build_podcast(self, data):
        try:
            self.log(f"Building podcast from itunes lookup data: {json.dumps(data, indent=4)}")

            itunes_url = data["collectionViewUrl"].split("?")[0]
            feed_url = data["feedUrl"]

            self.verify_feed_url(feed_url)

            pod_id = data["collectionId"]
            title = data["collectionName"]
            artist = data["artistName"]
            country = data['country']
            reviews_url = ITUNES_REVIEWS_URL.substitute(pod_id=pod_id)
            explicit = self.get_explicit(data)
            artwork_url = self.get_artwork_url(data)
            primary_genre, genres = self.get_genres(data)

            podcast = Podcast(
                title=title,
                artist=artist,
                pod_id=pod_id,
                feed_url=feed_url,
                reviews_url=reviews_url,
                artwork_url=artwork_url,
                country=country,
                explicit=explicit,
                primary_genre=primary_genre,
            )

            podcast = self.scrape_itunes(podcast, itunes_url)
            self.update_or_create_podcast(podcast, genres)
        except (IndexError, KeyError, WillyException) as e:
            raise WillyException(f"Error scraping podcast: {e}")

    def verify_feed_url(self, feed_url):
        self.log(f"Verifying feed url {feed_url}")

        try:
            response = requests.get(feed_url, timeout=10)
            if response.status_code != 200:
                raise WillyException(f"Feed url is not valid: {feed_url}")
        except requests.exceptions.ConnectionError as e:
            raise WillyException(f"Feed url verification error: {e}")

        self.log(f"Feed url verified: {feed_url}")

    def scrape_itunes(self, podcast, itunes_url):
        self.log(f"Scraping itunes data for {podcast.title}")

        try:
            response = requests.get(itunes_url, timeout=10)
            response.raise_for_status()
            tree = lxml_html.fromstring(response.text)
        except Exception as e:
            raise WillyException(f"Error scraping itunes: {e}")

        podcast.description = self.get_description(tree)
        podcast.copyright_text = self.get_copyright_text(tree)
        return podcast

    def update_or_create_podcast(self, podcast, genres):
        self.log(f"Updating or creating podcast {podcast.title}")

        with transaction.atomic():
            podcast, created = Podcast.objects.select_related(None).select_for_update().update_or_create(
                pod_id=podcast.pod_id,
                defaults={
                    "title": podcast.title,
                    "artist": podcast.artist,
                    "pod_id": podcast.pod_id,
                    "feed_url": podcast.feed_url,
                    "reviews_url": podcast.reviews_url,
                    "artwork_url": podcast.artwork_url,
                    "country": podcast.country,
                    "explicit": podcast.explicit,
                    "primary_genre": podcast.primary_genre,
                    "copyright_text": podcast.copyright_text,
                    "description": podcast.description,
                }
            )

            podcast.genres.set(genres)
            podcast.set_discriminated()
            podcast.save()

            if created:
                self.log(f"created podcast {podcast.title}")
            else:
                self.log(f"updated podcast {podcast.title}")
        return podcast

    def get_explicit(self, data):
        return True if data.get('trackExplicitness', None) == 'explicit' \
            or data.get('collectionExplicitness', None) == 'explicit' \
            or data.get('contentAdvisoryRating', None) == 'Explicit' \
            else False

    def get_artwork_url(self, data):
        try:
            artwork_url = data["artworkUrl600"].split("://")[1].replace("600x600bb.jpg", "")
            if "ssl" not in artwork_url:
                artwork_url = artwork_url.replace(".mzstatic", "-ssl.mzstatic")
            return artwork_url
        except (IndexError, KeyError) as e:
            raise WillyException(f"Error getting artwork url: {e}")

    def get_genres(self, data):
        try:
            genres = dict(zip(data["genreIds"], data["genres"]))
            genres = map(lambda genre: Genre(genre_id=genre[0], title=genre[1]), genres.items())
            genres = set(filter(lambda genre: genre.title != UNWANTED_GENRE, genres))

            primary_genre_title = data["primaryGenreName"]
            if primary_genre_title == UNWANTED_GENRE:
                primary_genre_title = genres.pop().title

            primary_genre = Genre.objects.get(title=primary_genre_title)
            genres = set(map(lambda genre: self.get_or_create_genre(genre), genres))
            return primary_genre, genres
        except (IndexError, KeyError) as e:
            raise WillyException(f"Error getting genres: {e}")

    def get_or_create_genre(self, genre):
        with transaction.atomic():
            genre, created = Genre.objects.get_or_create(genre_id=genre.genre_id)

        if created:
            self.log(f"Created genre {genre.title}")
        else:
            self.log(f"Updated genre {genre.title}")
        return genre

    def get_description(self, response):
        try:
            return response.xpath(DESCRIPTION_SELECTOR)[0].strip()
        except IndexError:
            return ""

    def get_copyright_text(self, response):
        try:
            copyright_text = response.xpath(COPYRIGHT_TEXT_SELECTOR)[0].strip()
        except IndexError:
            return DEFAULT_COPYRIGHT_TEXT
        return copyright_text if copyright_text else DEFAULT_COPYRIGHT_TEXT
