import 'dart:async';

import "formats/FileFormat.dart";

class Resource<T> {
    final String path;
    T object;
    final FileFormat<T,dynamic> format;
    List<Completer<T>> listeners = <Completer<T>>[];

    Resource(String this.path, FileFormat<T,dynamic> this.format);

    Future<T> getObject(bool forceCanonical) async {
        if (forceCanonical) {
            return this.object;
        }
        return this.format.processGetResource(this.object);
    }

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
            listener.complete(this.format.processGetResource(item));
        }
        listeners.clear();
    }

    Future<void> purge() async {
        if (this.object == null) { return; }
        await this.format.processPurgeResource(this.object);
    }

    void error(Object error) {
        for (final Completer<T> listener in listeners) {
            listener.completeError(error);
        }
        listeners.clear();
    }
}