import 'dart:async';

class Resource<T> {
    final String path;
    T object;
    List<Completer<T>> listeners = <Completer<T>>[];

    Resource(String this.path);

    Future<T> addListener() {
        if (this.object != null) {
            throw Exception("Attempting to add listener after resource population: $path");
        }
        final Completer<T> listener = new Completer<T>();
        this.listeners.add(listener);
        return listener.future;
    }

    void populate(T item) {
        if (this.object != null) {
            throw Exception("Resource ($path) already loaded");
        }
        this.object = item;
        for (final Completer<T> listener in listeners) {
            listener.complete(this.object);
        }
        listeners.clear();
    }

    void error(Object error) {
        for (final Completer<T> listener in listeners) {
            listener.completeError(error);
        }
        listeners.clear();
    }
}