# dop3pod
This will be the 3.0 version of my old pet project [dopepod](https://github.com/cyanidesayonara/dopepod).

As before, dopepod will be a web app capable of searching and playing thousands of free podcasts.

This time it will be made with something old, something new, something borrowed and something Vue. 

# Ingredients
* Python 3  
* Django Rest Framework  
* Celery
* Vue

# Installation
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
* Add the following lines to the .env file  
  ```SECRET_KEY=asd123```  
  ```ALLOWED_HOSTS='localhost'```  
  ```DATABASE_URL=sqlite:///db.sqlite3```  
  ```AMQP_URL='redis://localhost:6379'```
* Run migrations  
  ```python manage.py migrate```
* Create super user  
  ```python manage.py createsuperuser```
* Run server  
  ```python manage.py runserver```

# Further reading
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
