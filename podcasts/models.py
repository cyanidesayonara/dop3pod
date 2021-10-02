from django.db import models


class Podcast(models.Model):
    title = models.CharField(max_length=200)
    feed_url = models.CharField(max_length=200)
    artwork_url = models.CharField(max_length=200)

    objects = models.Manager()

    def __str__(self):
        return self.title
