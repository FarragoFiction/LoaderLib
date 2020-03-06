import "dart:async";
import "dart:typed_data";

import "package:archive/archive.dart";

import 'FileFormat.dart';

class ZipFormat extends BinaryFileFormat<Archive> {
    static final ZipDecoder _decoder = new ZipDecoder();
    static final ZipEncoder _encoder = new ZipEncoder();

    @override
    String mimeType() => "application/zip";

    @override
    Future<Archive> read(ByteBuffer input) async => _decoder.decodeBytes(input.asUint8List().toList());

    @override
    Future<ByteBuffer> write(Archive data) async {
        final Uint8List list = Uint8List.fromList(_encoder.encode(data, level: Deflate.BEST_COMPRESSION));
        return list.buffer;
    }

    @override
    String header() => "";
}