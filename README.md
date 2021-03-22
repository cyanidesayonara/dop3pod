# dop3pod
This will be the 3.0 version of my dear old pet project [dopepod](https://github.com/cyanidesayonara/dopepod).

dopepod will be a web/Android/iOS app capable of searching and playing thousands of free podcasts.

# Ingredients
* Python 3  
* Django Rest Framework  
* Celery
* Flutter

# Startup (docker)
* Install docker & docker-compose  
  https://docs.docker.com/compose/
* Start project with postgresql, redis & celery  
  ```docker-compose up --build```

# Startup (local)
https://docs.djangoproject.com/en/3.1/intro/tutorial01/

* Install Python 3  
  https://www.python.org/downloads/
* Install Redis  
  https://stackabuse.com/asynchronous-tasks-in-django-with-redis-and-celery/  
* Create and activate a virtual environment  
  ```python -m venv venv```  
  ```source venv/bin/activate```
* Install requirements.txt  
  ```pip install -r requirements.txt```  
* Create a file for environment variables  
  ```touch .env```
* Add the following to the created .env file
  ```
  SECRET_KEY=asd123  
  ALLOWED_HOSTS='localhost'  
  CELERY_BROKER='redis://localhost:6379'
  ```
* Start redis service and run it in a separate terminal  
  ```celery -A dop3pod worker -l info```
* Run migrations  
  ```python manage.py migrate```
* Create super user  
  ```python manage.py createsuperuser```
* Run server  
  ```python manage.py runserver```

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

## Dockerizing
https://soshace.com/dockerizing-django-with-postgres-redis-and-celery/
https://github.com/chrisk314/django-celery-docker-example
https://testdriven.io/blog/dockerizing-django-with-postgres-gunicorn-and-nginx/
