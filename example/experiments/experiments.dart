import "dart:async";
import "dart:html";

import "package:LoaderLib/Loader.dart";

Future<void> main() async {

    /*Future<void> testFuture = new Future<void>.delayed(Duration(milliseconds: 10), () { throw Error(); })
        ..then((void _) { print("testFuture!"); })
        ..catchError((Object e) => null);*/

    try {
        await new Future<void>.delayed(Duration(milliseconds: 10), () { throw Exception("poot"); });
    } on Exception catch(e) {
        print("caught $e");
    }

    try {
        await Loader.getResource("nonExistentFile.txt");
    } on ProgressEvent catch(e) {
        print("caught $e");
    }
}


