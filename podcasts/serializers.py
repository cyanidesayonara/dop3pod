from rest_framework import serializers
from podcasts.models import Podcast


class PodcastSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Podcast
        fields = ['title', 'feed_url', 'artwork_url']
