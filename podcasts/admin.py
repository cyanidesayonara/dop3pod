from django.contrib import admin
from podcasts.models import Podcast, Genre, Episode, User


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'username',
        'bio'
    )
    fields = (
        'id',
        'username',
        'bio'
    )

@admin.register(Podcast)
class PodcastAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'title',
        'artist',
        'pod_id',
        'feed_url',
        'artwork_url',
        'reviews_url',
        'country',
        'explicit',
        'primary_genre',
        'description',
        'copyright_text',
        'discriminate',
        'view_count'
    )
    fields = (
        'id',
        'title',
        'artist',
        'pod_id',
        'feed_url',
        'artwork_url',
        'reviews_url',
        'country',
        'explicit',
        'primary_genre',
        'description',
        'copyright_text',
        'discriminate',
        'view_count'
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
