from django.contrib import admin

from podcasts.models import Podcast


@admin.register(Podcast)
class PodcastAdmin(admin.ModelAdmin):
    list_display = ('title', 'feed_url', 'artwork_url')
    fields = ('title', 'feed_url', 'artwork_url')
