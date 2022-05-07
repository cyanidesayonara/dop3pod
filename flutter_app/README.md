# dop3pod flutter app

* Install flutter & Android Studio
  https://docs.flutter.dev/get-started/install/linux
* Create a file for environment variables  
  ```touch .env```
* Add the following to the created .env file to run app against local backend
  ```
  FLUTTER_HOSTNAME=http://10.0.2.2
  ```
* Run the flutter app in Android Studio or from the command line  
  ```flutter run lib/main.dart```