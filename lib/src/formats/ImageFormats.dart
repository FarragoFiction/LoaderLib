import "dart:async";
import "dart:html";
import "dart:typed_data";

import "../loader.dart";
import "FileFormat.dart";

abstract class ImageFileFormat extends BinaryFileFormat<ImageElement> {

    @override
    Future<String> objectToDataURI(ImageElement object) async {
        final CanvasElement canvas = new CanvasElement(width: object.width, height: object.height)..context2D.drawImage(object, 0, 0);
        final Blob blob = await canvas.toBlob(this.mimeType());

        return Loader.createBlobUrl(blob);
    }

    @override
    Future<ImageElement> requestObjectFromUrl(String url) async {
        final Completer<ImageElement> callback = new Completer<ImageElement>();
        final ImageElement img = new ImageElement()..crossOrigin="anonymous";
        img.onError.first.then((Event e) { callback.completeError(img); });
        img.onLoad.first.then((Event e) { callback.complete(img); });
        img.src = url;
        return callback.future;
    }

    @override
    Future<ImageElement> read(ByteBuffer input) async {
        final String url = await this.dataToDataURI(input);
        return requestObjectFromUrl(url);
    }

    @override
    Future<ByteBuffer> write(ImageElement data) => throw Exception("Write not implemented");

    @override
    /// Images get copies of themselves unless canonical is forced!
    Future<ImageElement> processGetResource(ImageElement resource) {
        return this.requestObjectFromUrl(resource.src ?? "");
    }

    @override
    /// Clean up any blob url that has been created when an image is purged
    Future<void> processPurgeResource(ImageElement resource) async {
        Loader.revokeBlobUrl(resource.src);
    }
}

class PngFileFormat extends ImageFileFormat {
    static final String _header = String.fromCharCodes(<int>[137, 80, 78, 71, 13, 10, 26, 10]);

    @override
    String mimeType() => "image/png";

    @override
    String header() => _header;
}

class GifFileFormat extends ImageFileFormat {
    static const String _header = "GIF89a";

    @override
    String mimeType() => "image/gif";

    @override
    String header() => _header;
}

class JpegFileFormat extends ImageFileFormat {
    static final String _header = String.fromCharCodes(<int>[0xFF, 0xD8, 0xFF, 0xE0]);

    @override
    String mimeType() => "image/jpeg";

    @override
    String header() => _header;
}