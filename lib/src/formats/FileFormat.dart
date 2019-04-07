import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import "package:CommonLib/Utility.dart";

import 'Formats.dart';

typedef LoadButtonCallback<T> = void Function(T object, String filename);

abstract class FileFormat<T,U> {
    List<String> extensions = <String>[];

    String mimeType();
    String header();

    bool identify(U data);

    Future<U> write(T data);
    Future<T> read(U input);

    Future<U> fromBytes(ByteBuffer buffer);

    Future<String> dataToDataURI(U data);
    Future<String> objectToDataURI(T object) async => dataToDataURI(await write(object));

    Future<U> readFromFile(File file);
    Future<T> readObjectFromFile(File file) async => read(await readFromFile(file));

    Future<U> requestFromUrl(String url);
    Future<T> requestObjectFromUrl(String url) async => read(await requestFromUrl(url));

    static Element loadButton<T,U>(FileFormat<T,U> format, LoadButtonCallback<T> callback, {bool multiple = false, String caption = "Load file"}) =>
        loadButtonVersioned(<FileFormat<T,U>>[format], callback, multiple:multiple, caption:caption);

    static Element loadButtonVersioned<T,U>(List<FileFormat<T,U>> formats, LoadButtonCallback<T> callback, {bool multiple = false, String caption = "Load file"}) {
        final Element container = new DivElement();

        final FileUploadInputElement upload = new FileUploadInputElement()..style.display="none"..multiple=multiple;

        final Set<String> extensions = <String>{};

        for (final FileFormat<T,U> format in formats) {
            extensions.addAll(Formats.getExtensionsForFormat(format));
        }

        if (!extensions.isEmpty) {
            upload.accept = extensions.map((String ext) => ".$ext").join(",");
        }

        upload.onChange.listen((Event e) async {
            if (upload.files.isEmpty) { return; }

            for (final File file in upload.files) {
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

    static Element saveButton<T,U>(FileFormat<T,U> format, Generator<T> objectGetter, {String caption = "Save file", Generator<String> filename = defaultFilename}) {
        final Element container = new DivElement();

        final ButtonElement download = new ButtonElement()..text=caption;

        final AnchorElement link = new AnchorElement()..style.display="none";

        download.onClick.listen((Event e) async {
            final T object = objectGetter();
            if (object == null) { return; }
            final String URI = await format.objectToDataURI(object);
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
    Future<String> dataToDataURI(ByteBuffer data) async =>
        Url.createObjectUrlFromBlob(new Blob(<dynamic>[data.asUint8List()], mimeType()));

    @override
    Future<ByteBuffer> readFromFile(File file) async {
        final FileReader reader = new FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        if (reader.result is Uint8List) {
            final Uint8List list = reader.result;
            return list.buffer;
        }
        return null;
    }

    @override
    Future<ByteBuffer> requestFromUrl(String url) async {
        final Completer<ByteBuffer> callback = new Completer<ByteBuffer>();
        HttpRequest.request(url, responseType: "arraybuffer", mimeType: this.mimeType()).then((HttpRequest request) {
            final ByteBuffer buffer = request.response;
            callback.complete(buffer);
        });
        return callback.future;
    }
}

abstract class StringFileFormat<T> extends FileFormat<T,String> {
    @override
    bool identify(String data) => data.startsWith(header());

    @override
    Future<String> fromBytes(ByteBuffer buffer) async {
        final StringBuffer sb = new StringBuffer();
        final Uint8List ints = buffer.asUint8List();
        for (final int i in ints) {
            sb.writeCharCode(i);
        }
        return sb.toString();
    }

    @override
    Future<String> dataToDataURI(String data) async {
        // \ufeff is the UTF8 byte marker, needed to make sure it's interpreted correctly!
        return Url.createObjectUrlFromBlob(new Blob(<dynamic>["\ufeff", data], mimeType()));
    }

    @override
    Future<String> readFromFile(File file) async {
        final FileReader reader = new FileReader();
        reader.readAsText(file);
        await reader.onLoad.first;
        if (reader.result is String) {
            return reader.result;
        }
        return null;
    }

    @override
    Future<String> requestFromUrl(String url) async {
        return HttpRequest.getString(url);
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
    String header() => "";
}