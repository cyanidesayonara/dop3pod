import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dop3pod.settings')

app = Celery('dop3pod')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()
