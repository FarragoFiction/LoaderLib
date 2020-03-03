import "dart:async";
import "dart:html";

import "package:archive/archive.dart";
import "package:LoaderLib/Loader.dart";

Future<void> main() async {

    final Archive zip = await Loader.getResource("folderpack.zip");

    DataPack pack = new DataPack(zip, path: "examplefolder/someotherfolder");
}


