from rest_framework import serializers
from podcasts.models import Podcast, Genre, Episode


class PodcastSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Podcast
        fields = [
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
            'genres',
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


class EpisodeSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Episode
        fields = [
            'podcast',
            'pub_date',
            'title',
            'description',
            'length',
            'url',
            'kind',
            'size',
        ]
