# dop3pod
(This is version 3.0 of my dear old pet project
[dopepod](https://github.com/cyanidesayonara/dopepod))

dopepod is a simple
[Android app](https://play.google.com/store/apps/details?id=com.cyanidesayonara.dopepod)
for searching and playing thousands of free podcasts found online

# Ingredients
* Python 3  
* Django Rest Framework
* Scrapy
* PostgreSQL
* Docker
* Celery
* Redis
* Dart
* Flutter

# Startup
## Backend
#### Install Docker & Docker Compose  
https://docs.docker.com/compose/

#### Create a file for environment variables  
```
touch .env
```

#### Add the following default settings to the created .env file
```
SECRET_KEY=123
DEBUG=True
ALLOWED_HOSTS='localhost 10.0.2.2'
DATABASE_URL=postgres://postgres:postgres@postgres:5432/postgres
LOGGING_LEVEL=INFO
CELERY_BROKER='redis://redis:6379/0'
REDIS_URL='redis://redis:6379'

SQL_ENGINE=django.db.backends.postgresql
SQL_DATABASE=postgres
SQL_USER=postgres
SQL_PASSWORD=postgres
SQL_HOST=postgres
SQL_PORT=5432

POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

#### Run the Docker Compose startup script:
```
docker-compose up --build
```

#### This will start the following services:
* Django REST Framework API (web)
* PostgreSQL database (postgres)
* Redis cache & message broker (redis)
* Celery worker (celery_worker_1 & celery_worker_2)

## App
#### Install Flutter, Dart & Android Studio
https://docs.flutter.dev/get-started/install  
https://dart.dev/get-dart  
https://developer.android.com/studio/install  

#### Create a file for environment variables in flutter_app folder 
```
cd flutter_app
touch .env
```

#### Add the following to the created .env file
```
FLUTTER_HOSTNAME=http://10.0.2.2
```

#### Run the flutter app in Android Studio or from the command line  
```
flutter run lib/main.dart
```

## References & further reading
### Server setup
https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-20-04  
https://www.digitalocean.com/community/tutorials/how-to-set-up-django-with-postgres-nginx-and-gunicorn-on-ubuntu-20-04

### Logging
https://docs.djangoproject.com/en/3.1/topics/logging/  
https://lincolnloop.com/blog/django-logging-right-way/

### Celery
https://medium.com/swlh/python-developers-celery-is-a-must-learn-technology-heres-how-to-get-started-578f5d63fab3  
https://simpleisbetterthancomplex.com/tutorial/2017/08/20/how-to-use-celery-with-django.html  
https://docs.celeryproject.org/en/stable/userguide/daemonizing.html#daemonizing

### Django REST Framework
https://www.django-rest-framework.org/tutorial/quickstart/

### Flutter
https://flutter.dev/docs/get-started/install  
https://flutter.dev/docs/cookbook/networking/fetch-data  
https://suragch.medium.com/background-audio-in-flutter-with-audio-service-and-just-audio-3cce17b4a7d  

### Dockerizing
https://soshace.com/dockerizing-django-with-postgres-redis-and-celery/  
https://github.com/chrisk314/django-celery-docker-example  
https://testdriven.io/blog/dockerizing-django-with-postgres-gunicorn-and-nginx/  
https://medium.com/swlh/django-deployed-docker-compose-1446909a0df9  
