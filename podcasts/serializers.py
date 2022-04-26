from rest_framework import serializers
from podcasts.models import Podcast, Genre


class PodcastSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Podcast
        fields = [
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
            'discriminate'
        ]


class GenreSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Genre
        fields = [
            'title',
            'genre_id',
            'supergenre'
        ]
