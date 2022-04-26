import logging
from django.db import models

logger = logging.getLogger(__name__)

UNWANTED_ARTWORK_URL = "is4.mzstatic.com/image/thumb/Music6/v4/00/83/44/008344f6-7d9f-2031-39c1-107020839411/source/"
UNWANTED_GENRE_ID = 1314


class GenreManager(models.Manager):
    def get_queryset(self):
        return super(GenreManager, self).get_queryset().select_related("supergenre")


class Genre(models.Model):
    title = models.CharField(primary_key=True, max_length=50)
    genre_id = models.IntegerField(unique=True)
    supergenre = models.ForeignKey("podcasts.Genre", on_delete=models.SET_NULL, null=True, default=None)

    objects = GenreManager()

    class Meta:
        ordering = ("title",)


class PodcastManager(models.Manager):
    def get_queryset(self):
        return super(PodcastManager, self).get_queryset().select_related("genre", "genre__supergenre")


class Podcast(models.Model):
    title = models.CharField(max_length=1000)
    artist = models.CharField(max_length=1000)
    pod_id = models.IntegerField(unique=True)
    feed_url = models.CharField(max_length=1000)
    reviews_url = models.CharField(max_length=1000)
    artwork_url = models.CharField(max_length=1000)
    country = models.CharField(max_length=50)
    explicit = models.BooleanField(default=False)
    primary_genre = models.ForeignKey(Genre, models.SET_NULL, blank=True, null=True, related_name="genre_primary")
    genres = models.ManyToManyField(Genre, related_name="genre_genres")
    copyright_text = models.CharField(max_length=5000)
    description = models.TextField(max_length=5000)
    discriminate = models.BooleanField(default=False)

    objects = models.Manager()

    class Meta:
        ordering = ['title', 'discriminate']
        indexes = [models.Index(fields=['artist', 'primary_genre'])]

    def __str__(self):
        return self.title

    def set_discriminated(self):
        if self.primary_genre is not None and self.primary_genre.genre_id == UNWANTED_GENRE_ID\
                or self.artwork_url == UNWANTED_ARTWORK_URL:
            self.discriminate = True
