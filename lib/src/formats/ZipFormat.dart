import "dart:async";
import "dart:typed_data";

import "package:archive/archive.dart";

import 'FileFormat.dart';

class ZipFormat extends BinaryFileFormat<Archive> {
    static final ZipDecoder _decoder = new ZipDecoder();
    static final ZipEncoder _encoder = new ZipEncoder();

    @override
    String mimeType() => "application/x-tar";

    @override
    Future<Archive> read(ByteBuffer input) async => _decoder.decodeBytes(input.asUint8List());

    @override
    Future<ByteBuffer> write(Archive data) async {
        final Uint8List list = _encoder.encode(data);
        return list.buffer;
    }

    @override
    String header() => "";
}