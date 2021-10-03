# dop3pod
This will be the 3.0 version of my dear old pet project [dopepod](https://github.com/cyanidesayonara/dopepod).

dopepod will be a web/Android/iOS app capable of searching and playing thousands of free podcasts.

# Ingredients
* Python 3  
* Django Rest Framework  
* Celery
* Redis
* Nginx
* Dart
* Go

# Startup
* Install docker & docker-compose  
  https://docs.docker.com/compose/
* Create a file for environment variables  
  ```touch .docker-env```
* Add the following to the created .docker-env file
  ```
  SECRET_KEY=123
  DEBUG=True
  ALLOWED_HOSTS='localhost'
  DATABASE_URL=postgres://postgres:postgres@postgres:5432/postgres
  LOGGING_LEVEL=INFO
  CELERY_BROKER='redis://redis:6379/0'

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
* Start the django rest framework api with postgresql, redis, celery & nginx  
  ```docker-compose up --build```

# References & further reading
## Server setup
https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-20-04  
https://www.digitalocean.com/community/tutorials/how-to-set-up-django-with-postgres-nginx-and-gunicorn-on-ubuntu-20-04

## Logging
https://docs.djangoproject.com/en/3.1/topics/logging/  
https://lincolnloop.com/blog/django-logging-right-way/

## Celery
https://medium.com/swlh/python-developers-celery-is-a-must-learn-technology-heres-how-to-get-started-578f5d63fab3  
https://simpleisbetterthancomplex.com/tutorial/2017/08/20/how-to-use-celery-with-django.html
https://docs.celeryproject.org/en/stable/userguide/daemonizing.html#daemonizing

## Let's Encrypt
https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-20-04

## Django REST Framework
https://www.django-rest-framework.org/tutorial/quickstart/

## Flutter
https://flutter.dev/docs/get-started/install
https://flutter.dev/docs/cookbook/networking/fetch-data

## Dockerizing
https://soshace.com/dockerizing-django-with-postgres-redis-and-celery/
https://github.com/chrisk314/django-celery-docker-example
https://testdriven.io/blog/dockerizing-django-with-postgres-gunicorn-and-nginx/
https://medium.com/swlh/django-deployed-docker-compose-1446909a0df9
