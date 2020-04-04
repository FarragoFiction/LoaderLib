import "dart:async";
import "dart:html";
import "dart:typed_data";

import "package:archive/archive.dart" as A;
import "package:LoaderLib/Archive.dart";
import "package:LoaderLib/Loader.dart";

Future<void> main() async {

    /*final Archive zip = await Loader.getResource("folderpack.zip");

    DataPack pack = new DataPack(zip, path: "examplefolder/someotherfolder");*/

    /*String text = await Loader.getResource("testdata.txt");
    print("Before mount: $text");

    final DataPack pack = await Loader.loadDataPack("testpack.zip");

    text = await Loader.getResource("testdata.txt");
    print("After mount: $text");

    Loader.unmountDataPack(pack);

    text = await Loader.getResource("testdata.txt");
    print("After unmount: $text");

    final ByteBuffer buffer = await Formats.text.toBytes("this is test data");

    final Archive testZip = new Archive();
    final List<int> bytes = buffer.asUint8List().toList();
    final ArchiveFile testFile = new ArchiveFile("testdata.txt", bytes.length, bytes);
    testZip.addFile(testFile);

    document.body.append(FileFormat.saveButton(Formats.zip, () => testZip, caption: "zip test", filename: () => "downtest.zip"));
    document.body.append(FileFormat.saveButton(Formats.text, () => "this is a test text file", caption: "text test", filename: () => "downtest.txt"));
    */

    String thingy = "hello";
    String filename = "file.txt";

    Archive archive = new Archive();
    await archive.setFile(filename, thingy);
    await archive.setFile(filename, thingy);
    print(archive.files.toList());

    String retrieved = await archive.getFile(filename);
    print("retrieved: $retrieved");

    await Loader.getResource("thing.png"); // not there
}


