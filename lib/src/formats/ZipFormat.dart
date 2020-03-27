import "dart:async";
import "dart:typed_data";

import "package:archive/archive.dart" as zip;

import '../archive.dart';
import 'FileFormat.dart';

class ZipFormat extends BinaryFileFormat<Archive> {
    @override
    String mimeType() => "application/zip";

    @override
    Future<Archive> read(ByteBuffer input) async => new Archive.fromRawArchive(RawZipFormat._decoder.decodeBytes(input.asUint8List().toList()));

    @override
    Future<ByteBuffer> write(Archive data) async {
        final Uint8List list = Uint8List.fromList(RawZipFormat._encoder.encode(data.rawArchive, level: zip.Deflate.BEST_COMPRESSION));
        return list.buffer;
    }

    @override
    String header() => "";
}

class RawZipFormat extends BinaryFileFormat<zip.Archive> {
    static final zip.ZipDecoder _decoder = new zip.ZipDecoder();
    static final zip.ZipEncoder _encoder = new zip.ZipEncoder();

    @override
    String mimeType() => "application/zip";

    @override
    Future<zip.Archive> read(ByteBuffer input) async => _decoder.decodeBytes(input.asUint8List().toList());

    @override
    Future<ByteBuffer> write(zip.Archive data) async {
        final Uint8List list = Uint8List.fromList(_encoder.encode(data, level: zip.Deflate.BEST_COMPRESSION));
        return list.buffer;
    }

    @override
    String header() => "";
}