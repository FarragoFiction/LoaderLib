
class LoaderException implements Exception {
    String message;
    dynamic errorObject;

    LoaderException(String this.message, [dynamic this.errorObject]);

    @override
    String toString() => "LoaderException: $message${errorObject!=null ? ", error object: $errorObject" : ""}";
}