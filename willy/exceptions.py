from rest_framework.exceptions import APIException


class WillyException(APIException):
    status_code = 666
    default_detail = 'An error occurred'
    default_code = 'willy_error'
