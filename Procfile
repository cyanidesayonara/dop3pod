worker: celery -A dop3pod worker -B -l INFO
web: gunicorn dop3pod.wsgi --log-file -
release: python manage.py migrate
