import "dart:typed_data";

import 'package:LoaderLib/Loader.dart';
import "package:archive/archive.dart" as raw;

import "formats/FileFormat.dart";

class Archive {
  final raw.Archive rawArchive;

  late Iterable<String> _files;
  Iterable<String> get files => _files;

  Archive() : rawArchive = new raw.Archive() {
    _init();
  }

  Archive.fromRawArchive(raw.Archive this.rawArchive) {
    _init();
  }

  void _init() {
    _files = rawArchive.files.map((raw.ArchiveFile file) => file.name);
  }

  Future<void> setFile<T, U>(String name, T data, {FileFormat<T, U>? format}) async {
    format ??= Formats.getFormatForFilename(name);
    final raw.ArchiveFile? existingFile = rawArchive.findFile(name);

    final ByteBuffer bytes = await format.toBytes(await format.write(data));
    final raw.ArchiveFile newFile = new raw.ArchiveFile(name, bytes.lengthInBytes, bytes.asUint8List().toList());

    if (existingFile != null) {
      final int id = rawArchive.files.indexOf(existingFile);
      rawArchive.files[id] = newFile;
    } else {
      rawArchive.addFile(newFile);
    }
  }

  Future<T?> getFile<T, U>(String name, {FileFormat<T,U>? format}) async {
    final raw.ArchiveFile? file = rawArchive.findFile(name);
    if (file == null) { return null; }

    format ??= Formats.getFormatForFilename(name);

    final ByteBuffer data = new Uint8List.fromList(file.content).buffer;
    final T item = await format.read(await format.fromBytes(data));

    return item;
  }
}
