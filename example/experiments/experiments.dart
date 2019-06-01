import "dart:async";
import "dart:html";

import "package:LoaderLib/Loader.dart";

Future<void> main() async {

    Future<void> testFuture = new Future<void>.delayed(Duration(milliseconds: 10), () { throw Exception(); })
        .then((void _) { print("testFuture!"); })
        .catchError((Object e) => print("caught $e"));

    try {
        await Loader.getResource("nonExistentFile.txt");
    } on Exception catch(e) {
        print("caught $e");
    }

    try {
        await Loader.getResource("nonExistentFile.txt");
    } on Exception catch(e) {
        print("caught $e");
    }
}


