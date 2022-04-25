import scrapy
import requests
from django.db import transaction
from podcasts.models import Genre, Podcast
from willy.exceptions import WillyExeption
from lxml import html as lxml_html

UNWANTED_GENRE = "Podcasts"


class WillyTheSpider(scrapy.Spider):
    name = 'willy'
    allowed_domains = ['itunes.apple.com']
    start_urls = ['https://itunes.apple.com/us/genre/podcasts/id26']

    def parse(self, response):
        self.create_or_update_genres(response)
        yield from self.create_or_update_podcasts(response)

    def create_or_update_podcasts(self, response):
        for link in response.xpath('//div[@id="genre-nav"]/div/ul/li/a'):
            url = link.xpath('@href').extract_first().split('?')[0]
            yield scrapy.Request(
                url, meta={'dont_redirect': True}, callback=self.parse_podcasts, dont_filter=True)
        for link in response.xpath('//div[@id="genre-nav"]/div/ul/li/a'):
            url = link.xpath('@href').extract_first().split('?')[0]
            yield scrapy.Request(
                url, meta={'dont_redirect': True}, callback=self.parse_alphabetical_index, dont_filter=True)
        for link in response.xpath('//div[@id="genre-nav"]/div/ul/li/ul/li/a'):
            url = link.xpath('@href').extract_first().split('?')[0]
            yield scrapy.Request(
                url, meta={'dont_redirect': True}, callback=self.parse_podcasts, dont_filter=True)
        for link in response.xpath('//div[@id="genre-nav"]/div/ul/li/ul/li/a'):
            url = link.xpath('@href').extract_first().split('?')[0]
            yield scrapy.Request(
                url, meta={'dont_redirect': True}, callback=self.parse_alphabetical_index, dont_filter=True)

    def create_or_update_genres(self, response):
        with transaction.atomic():
            for genre in response.xpath('//div[@id="genre-nav"]/div[@class="grid3-column"]/ul/li'):
                supergenre = genre.xpath('a/text()').extract_first()
                genre_id = genre.xpath('a/@href').re_first(r'/id(\d+)')
                supergenre, created = Genre.objects.select_related(None).select_for_update().update_or_create(
                    name=supergenre,
                    genre_id=genre_id,
                    supergenre=None,
                )
                if created:
                    self.log(f"Created supergenre {supergenre}")
                else:
                    self.log(f"Updated supergenre {supergenre}")
                for subgenre in genre.xpath('ul/li'):
                    name = subgenre.xpath('a/text()').extract_first()
                    genre_id = subgenre.xpath('a/@href').re_first(r'/id(\d+)')
                    genre, created = Genre.objects.select_related(None).select_for_update().update_or_create(
                        name=name,
                        genre_id=genre_id,
                        supergenre=supergenre,
                    )
                    if created:
                        self.log(f"Created genre {name}")
                    else:
                        self.log(f"Updated genre {name}")

    def parse_alphabetical_index(self, response):
        """
        follows links to each pagination
        """

        for link in response.xpath('//div[@id="selectedgenre"]/ul/li/a'):
            url = response.url + '?' + link.xpath('@href').extract_first().split('&')[-1]
            yield scrapy.Request(url, meta={'dont_redirect': True}, callback=self.parse_pagination)

    def parse_pagination(self, response):
        """
        parses all podcasts on each page
        """

        for link in response.xpath('//div[@id="selectedgenre"]/ul[2]/li/a'):
            url = response.url + '&' + link.xpath('@href').extract_first().split('&')[-1].replace('#page', '')
            yield scrapy.Request(url, meta={'dont_redirect': True}, callback=self.parse_podcasts)

    def parse_podcasts(self, response):
        """
        gets pod_id from podcast link
        uses itunes lookup to scrape podcast data by pod_id
        """

        for link in response.xpath('//div[@id="selectedcontent"]/div/ul/li/a[contains(@href, "id")]'):
            pod_id = link.xpath('@href').re_first(r'/id(\w+)')
            url = f"https://itunes.apple.com/lookup?id={pod_id}"
            yield scrapy.Request(url, meta={'dont_redirect': True}, callback=self.scrape_podcast)

    def scrape_podcast(self, response):
        json_response = response.json()

        try:
            data = json_response["results"][0]
            return self.build_podcast(data, response)
        except (IndexError, KeyError) as e:
            raise WillyExeption(f"Error scraping podcast: {e}")

    def build_podcast(self, data, response):
        try:
            itunes_url = data["collectionViewUrl"].split("?")[0]
            feed_url = data["feedUrl"]

            self.verify_feed_url(feed_url)

            pod_id = data["collectionId"]
            title = data["collectionName"]
            artist = data["artistName"]
            country = data['country']
            reviews_url = f"https://itunes.apple.com/us/rss/customerreviews/id={pod_id}/json"
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
        except (IndexError, KeyError) as e:
            raise WillyExeption(f"Error scraping podcast: {e}")

    def verify_feed_url(self, feed_url):
        try:
            response = requests.get(feed_url, timeout=10)
            if response.status_code != 200:
                raise WillyExeption(f"Feed url is not valid {feed_url}")
        except requests.exceptions.ConnectionError as e:
            raise WillyExeption(f"Feed url verification error {e}")
        self.log(f"Feed url verified {feed_url}")

    def scrape_itunes(self, podcast, itunes_url):
        response = requests.get(itunes_url, timeout=10)
        try:
            response.raise_for_status()
            tree = lxml_html.fromstring(response.text)
        except Exception as e:
            raise WillyExeption(f"Error scraping itunes: {e}")
        podcast.description = self.get_description(tree)
        podcast.copyright_text = self.get_copyright_text(tree)
        return podcast

    def update_or_create_podcast(self, podcast, genres):
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
                self.log(f"created podcast {podcast}")
            else:
                self.log(f"updated podcast {podcast}")
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
            self.log(f"Error getting artwork url: {e}")
            raise WillyExeption(f"Error getting artwork url: {e}")

    def get_genres(self, data):
        try:
            genres = dict(zip(data["genreIds"], data["genres"]))
            genres = dict(filter(lambda item: item[1] != UNWANTED_GENRE, genres.items()))

            primary_genre = data["primaryGenreName"]
            if primary_genre == UNWANTED_GENRE:
                primary_genre = genres[0][1]

            primary_genre = Genre.objects.get(name=primary_genre)
            genres = set(map(lambda genre: self.get_or_create_genre(genre), genres.items()))
            return primary_genre, genres
        except (IndexError, KeyError) as e:
            self.log(f"Error getting genres: {e}")
            raise WillyExeption(f"Error getting genres: {e}")

    def get_or_create_genre(self, genre):
        return Genre.objects.get_or_create(genre_id=genre[0], name=genre[1])[0]

    def get_description(self, response):
        try:
            return response.xpath("//section[@class='product-hero-desc__section']/div/p/text()")[0].strip()
        except IndexError:
            return ""

    def get_copyright_text(self, response):
        try:
            copyright_text = response.xpath("//li[@class='tracklist-footer__item']/text()")[0].strip()
        except IndexError:
            copyright_text = "© All rights reserved"
        if not copyright_text:
            copyright_text = "© All rights reserved"
        return copyright_text
