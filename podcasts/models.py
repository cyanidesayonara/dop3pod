from datetime import timedelta
import re
import logging
import requests
from dateutil.parser import parse
from lxml import html as lxml_html
from lxml.etree import XML, ParserError, XMLSyntaxError
from django.db import models
from django.core.cache import cache
from django.utils.html import strip_tags

logger = logging.getLogger(__name__)

UNWANTED_ARTWORK_URL = "is4.mzstatic.com/image/thumb/Music6/v4/00/83/44/008344f6-7d9f-2031-39c1-107020839411/source/"
UNWANTED_GENRE_ID = 1314
MIN_SIZE = 50000
NAMESPACES = {
    "itunes": "http://www.itunes.com/dtds/podcast-1.0.dtd",
    "atom": "http://www.w3.org/2005/Atom",
    "im": "http://itunes.apple.com/rss",
}


def format_bytes(bts):
    num = 1
    power = 2 ** 10
    suffixes = {
        1: "KB",
        2: "MB",
        3: "GB",
        4: "TB"
    }

    if bts <= power**2:
        bts /= power
        return "{0:4.1f}{1}".format(bts, suffixes[num])
    while bts > power:
        num += 1
        bts /= power ** num
    return "{0:4.1f}{1}".format(bts, suffixes[num])


class GenreManager(models.Manager):
    def get_queryset(self):
        return super().get_queryset().select_related("supergenre")


class Genre(models.Model):
    title = models.CharField(primary_key=True, max_length=50)
    genre_id = models.IntegerField(unique=True)
    supergenre = models.ForeignKey(
        "podcasts.Genre", on_delete=models.SET_NULL, null=True, default=None)

    objects = GenreManager()

    class Meta:
        ordering = ("title",)


class PodcastManager(models.Manager):
    def get_queryset(self):
        return super().get_queryset().select_related("genre", "genre__supergenre")


class Podcast(models.Model):
    title = models.CharField(max_length=1000)
    artist = models.CharField(max_length=1000)
    pod_id = models.IntegerField(unique=True)
    feed_url = models.CharField(max_length=1000)
    reviews_url = models.CharField(max_length=1000)
    artwork_url = models.CharField(max_length=1000)
    country = models.CharField(max_length=50)
    explicit = models.BooleanField(default=False)
    primary_genre = models.ForeignKey(
        Genre, models.SET_NULL, blank=True, null=True, related_name="genre_primary")
    genres = models.ManyToManyField(Genre, related_name="genre_genres")
    copyright_text = models.CharField(max_length=5000)
    description = models.TextField(max_length=5000)
    discriminate = models.BooleanField(default=False)
    view_count = models.IntegerField(default=0)

    objects = models.Manager()

    class Meta:
        ordering = ['-view_count', 'title', 'discriminate']
        indexes = [models.Index(fields=['artist', 'primary_genre'])]

    def __str__(self):
        return str(self.title)

    def set_discriminated(self):
        if self.primary_genre is not None and self.primary_genre.genre_id == UNWANTED_GENRE_ID\
                or self.artwork_url == UNWANTED_ARTWORK_URL:
            self.discriminate = True


class Episode(models.Model):
    podcast = models.ForeignKey(Podcast, on_delete=models.CASCADE)
    pub_date = models.DateTimeField(default=None, null=True)
    title = models.CharField(max_length=1000)
    description = models.TextField(max_length=5000, null=True, blank=True)
    length = models.DurationField(null=True, blank=True)
    url = models.CharField(max_length=1000)
    kind = models.CharField(max_length=16)
    size = models.CharField(null=True, blank=True, max_length=16)

    class Meta:
        ordering = ("pub_date",)


def get_episodes(podcast):
    """
    returns a list of episodes using requests and lxml etree
    """

    results = cache.get(podcast.pod_id)
    if results:
        logger.debug("Results from cache for %s: %s episodes", podcast.pod_id, len(results))
        return results
    return fetch_episodes(podcast)


def fetch_episodes(podcast):
    feed_url = podcast.feed_url
    episodes = []

    try:
        response = requests.get(feed_url, timeout=5, allow_redirects=True)
        response.raise_for_status()
        tree = get_tree(response, feed_url)

        try:
            items = tree.findall("item")
        except AttributeError:
            logger.error("can\'t find items for %s", feed_url)
            items = []

        for index, item in enumerate(items):
            episode = Episode(
                id=index,
                podcast=podcast,
                title=get_title(item, feed_url),
                pub_date=get_pub_date(item, feed_url),
                description=get_description(item, feed_url),
                length=get_length(item, feed_url)
            )
            episode = get_enclosure_data(episode, item, feed_url)
            episodes.append(episode)

    except (requests.exceptions.HTTPError, requests.exceptions.ConnectionError,
            requests.exceptions.InvalidSchema, requests.exceptions.MissingSchema):
        logger.error("connection error for %s", feed_url)

    if episodes:
        episodes.sort(key=lambda ep: ep.pub_date, reverse=True)
        cache.set(podcast.pod_id, episodes, 60 * 60 * 24)
        logger.debug("Cacheing %s episodes from %s", len(episodes), feed_url)
    return episodes


def get_title(item, feed_url):
    title = ""
    try:
        title = item.find("title").text
    except AttributeError:
        try:
            title = item.find("itunes:subtitle").text
        except AttributeError:
            logger.error("can\'t get title for %s", feed_url)
    return title


def get_pub_date(item, feed_url):
    pub_date = None
    try:
        try:
            pub_date = item.find("pubDate").text
        except AttributeError:
            try:
                pub_date = item.find("pubdate").text
            except AttributeError:
                return pub_date
        return parse(pub_date)
    except (ValueError, TypeError):
        logger.error("can\'t parse pub_date for %s", feed_url)
        return pub_date


def get_description(item, feed_url):
    description = ""
    try:
        description = item.find("description").text
    except AttributeError:
        try:
            description = item.find("itunes:summary", NAMESPACES).text
        except AttributeError:
            logger.error("can\'t get description for %s", feed_url)
    return " ".join(strip_tags(description).split())


def get_enclosure_data(episode, item, feed_url):
    enclosure = item.find("enclosure")
    try:
        size = enclosure.get("length")
        if size and int(size) > MIN_SIZE:
            episode.size = format_bytes(int(size))
    except (AttributeError, ValueError):
        logger.error("can\'t get episode size for %s", feed_url)
    try:
        episode.url = enclosure.get("url").replace("http:", "")
        episode.kind = enclosure.get("type")
    except AttributeError:
        logger.error("can\'t get episode url/type/size for %s", feed_url)
    return episode


def get_length(item, feed_url):
    length = None
    try:
        length = item.find("itunes:duration", NAMESPACES).text
    except AttributeError:
        try:
            length = item.find("duration").text
        except AttributeError:
            logger.error("can\'t get length for %s", feed_url)
    return get_episode_length(length, feed_url)


def get_episode_length(length, feed_url):
    if length:
        if length.isdigit() and length != 0:
            return timedelta(seconds=int(length))
        return get_episode_length_again(length, feed_url)
    return length


def get_episode_length_again(length, feed_url):
    if re.search("[1-9]", length):
        if "." in length:
            length = length.split(".")
        elif ":" in length:
            length = length.split(":")
        else:
            return length

        try:
            hours = int(length[0])
            minutes = int(length[1])
            seconds = int(length[2])
            return timedelta(hours=hours, minutes=minutes, seconds=seconds)
        except (ValueError, IndexError):
            try:
                minutes = int(length[0])
                seconds = int(length[1])
                return timedelta(minutes=minutes, seconds=seconds)
            except (ValueError, IndexError):
                logger.error("can\'t parse length for %s", feed_url)
    return length


def get_tree(response, feed_url):
    try:
        root = XML(response.content)
    except (ParserError, XMLSyntaxError):
        logger.error("trouble with xml for %s", feed_url)

        try:
            root = lxml_html.fromstring(response.content)
            root = root.xpath("//rss")[0]
        except (ParserError, XMLSyntaxError):
            logger.error("no can do %s", feed_url)
            return None

    NAMESPACES.update(root.nsmap)
    tree = root.find("channel")
    return tree
