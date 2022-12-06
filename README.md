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
* Nginx
* Dart
* Flutter

# Startup
## Backend
#### Install Docker & Docker Compose  
https://docs.docker.com/compose/

#### Create a file for environment variables by copying the .env.example file and renaming it .env
```
cp .env.example .env
```

#### Run the Docker Compose startup script:
```
docker-compose up --build
```

#### This will start the following services:
* Django REST Framework API (web)
* Nginx web server (nginx)
* PostgreSQL database (postgres)
* Redis cache & message broker (redis)
* Celery worker (celery_worker_1 & celery_worker_2)

#### The web server will respond to http requests to http://localhost:8000
A different Nginx port number can be defined in the above ```.env``` file along
with many other settings

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

### Let's Encrypt
https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-20-04

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

### Auth
https://www.django-rest-framework.org/api-guide/authentication/
https://mattermost.com/blog/user-authentication-with-the-django-rest-framework-and-angular/
https://simpleisbetterthancomplex.com/tutorial/2018/11/22/how-to-implement-token-authentication-using-django-rest-framework.html
 
