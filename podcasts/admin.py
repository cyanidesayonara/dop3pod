from django.contrib import admin

from podcasts.models import Podcast, Genre, Episode


@admin.register(Podcast)
class PodcastAdmin(admin.ModelAdmin):
    list_display = (
        'title',
        'artist',
        'pod_id',
        'feed_url',
        'artwork_url',
        'reviews_url',
        'country',
        'explicit',
        'primary_genre',
        'copyright_text',
        'description',
        'discriminate'
    )
    fields = (
        'title',
        'artist',
        'pod_id',
        'feed_url',
        'artwork_url',
        'reviews_url',
        'country',
        'explicit',
        'primary_genre',
        'copyright_text',
        'description',
        'discriminate'
    )


@admin.register(Genre)
class GenreAdmin(admin.ModelAdmin):
    list_display = (
        'title',
        'genre_id',
        'supergenre'
    )
    fields = (
        'title',
        'genre_id',
        'supergenre'
    )


@admin.register(Episode)
class EpisodeAdmin(admin.ModelAdmin):
    list_display = (
        'podcast',
        'pub_date',
        'title',
        'description',
        'length',
        'url',
        'kind',
        'size',
    )
    fields = (
        'podcast',
        'pub_date',
        'title',
        'description',
        'length',
        'url',
        'kind',
        'size',
    )
