import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import "package:CommonLib/Utility.dart";
import 'package:LoaderLib/Loader.dart';

import "../loader.dart";

typedef LoadButtonCallback<T> = void Function(T object, String filename);

abstract class FileFormat<T,U> {
    Set<String> extensions = <String>{};

    String mimeType();
    String header();

    bool identify(U data);

    Future<U> write(T data);
    Future<T> read(U input);

    Future<U> fromBytes(ByteBuffer buffer);
    Future<ByteBuffer> toBytes(U data);

    Future<String> dataToDataURI(U data);
    Future<String> objectToDataURI(T object) async => dataToDataURI(await write(object));

    Future<U> readFromFile(File file);
    Future<T> readObjectFromFile(File file) async => read(await readFromFile(file));

    Future<U> requestFromUrl(String url);
    Future<T> requestObjectFromUrl(String url) async => read(await requestFromUrl(url));

    /// Called by the loader, not for manual use
    Future<T> processGetResource(T resource) async => resource;
    /// Called by the loader, not for manual use
    Future<void> processPurgeResource(T resource) async {}

    static Element loadButton<T,U>(FileFormat<T,U> format, LoadButtonCallback<T> callback, {bool multiple = false, String caption = "Load file", Set<String>? accept}) =>
        loadButtonVersioned(<FileFormat<T,U>>[format], callback, multiple:multiple, caption:caption, accept:accept);

    static Element loadButtonVersioned<T,U>(List<FileFormat<T,U>> formats, LoadButtonCallback<T> callback, {bool multiple = false, String caption = "Load file", Set<String>? accept}) {
        final Element container = new DivElement();

        final FileUploadInputElement upload = new FileUploadInputElement()..style.display="none"..multiple=multiple;

        if (accept == null) {
            accept = <String>{};

            for (final FileFormat<T, U> format in formats) {
                accept.addAll(format.extensions.map((String e) => ".$e"));
            }
        }

        if (!accept.isEmpty) {
            upload.accept = accept.join(",");
        }

        upload.onChange.listen((Event e) async {
            if (upload.files!.isEmpty) { return; }

            for (final File file in upload.files!) {
                for (final FileFormat<T, U> format in formats) {
                    final U output = await format.readFromFile(file);
                    if (output != null) {
                        callback(await format.read(output), file.name);
                        break;
                    }
                }
            }
            upload.value = null;
        });

        container
            ..append(upload)
            ..append(new ButtonElement()..text=caption..onClick.listen((Event e) => upload.click()));

        return container;
    }

    static String defaultFilename() => "download";

    static Element saveButton<T,U>(FileFormat<T,U> format, Generator<Future<T>> objectGetter, {String caption = "Save file", Generator<String> filename = defaultFilename}) {
        final Element container = new DivElement();

        final ButtonElement download = new ButtonElement()..text=caption;

        final AnchorElement link = new AnchorElement()..style.display="none";

        // hold on to the previous url so we can clean it up automatically
        String? previousUrl;

        download.onClick.listen((Event e) async {
            Loader.revokeBlobUrl(previousUrl);

            final T object = await objectGetter();
            if (object == null) { return; }
            final String URI = await format.objectToDataURI(object);
            previousUrl = URI;
            link
                ..download = filename()
                ..href = URI..click();
        });

        container..append(download)..append(link);

        return container;
    }
}

abstract class BinaryFileFormat<T> extends FileFormat<T,ByteBuffer> {
    @override
    bool identify(ByteBuffer data) {
        final String head = this.header();
        final List<int> headbytes = head.codeUnits;
        final List<int> bytes = data.asUint8List();
        for (int i=0; i<headbytes.length; i++) {
            if (bytes[i] != headbytes[i]) {
                return false;
            }
        }
        return true;
    }

    @override
    Future<ByteBuffer> fromBytes(ByteBuffer buffer) async => buffer;
    @override
    Future<ByteBuffer> toBytes(ByteBuffer data) async => data;

    @override
    Future<String> dataToDataURI(ByteBuffer data) async =>
        Loader.createBlobUrl(new Blob(<dynamic>[data.asUint8List()], mimeType()));

    @override
    Future<ByteBuffer> readFromFile(File file) async {
        final FileReader reader = new FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        if (reader.result is Uint8List) {
            final Uint8List list = reader.result! as Uint8List;
            return list.buffer;
        }
        throw LoaderException("FileReader unable to read binary file");
    }

    @override
    Future<ByteBuffer> requestFromUrl(String url) async {
        final Completer<ByteBuffer> callback = new Completer<ByteBuffer>();
        HttpRequest.request(url, responseType: "arraybuffer", mimeType: this.mimeType()).then<void>((HttpRequest request) {
            final ByteBuffer buffer = request.response;
            callback.complete(buffer);
        }).catchError(callback.completeError);
        return callback.future;
    }
}

abstract class StringFileFormat<T> extends FileFormat<T,String> {
    @override
    bool identify(String data) => data.startsWith(header());

    @override
    Future<String> fromBytes(ByteBuffer buffer) async {
        final File file = new File(<Object>[buffer.asUint8List()], "file from data");
        return readFromFile(file);
    }

    @override
    Future<ByteBuffer> toBytes(String data) async {
        // The extra byte sequence is the UTF-8 byte marker, to make sure it's interpreted correctly!
        final List<int> bytes = data.codeUnits.toList()..insertAll(0, <int>[0xEF,0xBB,0xBF]);
        return new Uint8ClampedList.fromList(bytes).buffer;
    }

    @override
    Future<String> dataToDataURI(String data) async {
        // \ufeff is the UTF8 byte marker, needed to make sure it's interpreted correctly!
        return Loader.createBlobUrl(new Blob(<dynamic>["\ufeff", data], mimeType()));
    }

    @override
    Future<String> readFromFile(File file) async {
        final FileReader reader = new FileReader();
        reader.readAsText(file);
        await reader.onLoad.first;
        if (reader.result is String) {
            return reader.result as String;
        }
        throw LoaderException("FileReader unable to read string file");
    }

    @override
    Future<String> requestFromUrl(String url) async {
        //return HttpRequest.getString(url);
        return HttpRequest.request(url, mimeType: this.mimeType()).then((HttpRequest request) => request.responseText!);
    }
}

// this is a little weird and sort of a special case, mostly for streaming audio
abstract class ElementFileFormat<T> extends FileFormat<T,String> {
    @override
    bool identify(String data) => true;

    @override
    Future<String> requestFromUrl(String url) async => url;

    @override
    Future<String> readFromFile(File file) => throw Exception("Element format doesn't read from files");

    @override
    Future<String> dataToDataURI(String data) async => data;

    @override
    Future<String> fromBytes(ByteBuffer buffer) => throw Exception("Element format doesn't read from buffers");

    @override
    Future<ByteBuffer> toBytes(String data) => throw Exception("Element format doesn't write to buffers");

    @override
    String header() => "";
}