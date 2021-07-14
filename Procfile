release: python manage.py migrate
web: gunicorn dop3pod.wsgi --log-file -
worker: celery -A dop3pod worker -l info -P prefork
