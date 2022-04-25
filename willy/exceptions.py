from rest_framework.exceptions import APIException


class WillyExeption(APIException):
    status_code = 666
    default_detail = 'Unable to create podcast'
    default_code = '123'
