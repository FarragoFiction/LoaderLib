@TestOn("browser")

import "dart:html";

import "package:archive/archive.dart";
import 'package:LoaderLib/Loader.dart';
import 'package:test/test.dart';

void main() {
    // doesn't seem to work in test
    /*test("Package Path Resolution", () async {
        final String file = await Loader.getResource("package:CommonLib/src/analysis_options.yaml", format: Formats.text);
        expect(file, null);
    });*/

    test("Loading a file with a specified format", () async {
        final String file = await Loader.getResource("testdata.txt", format: Formats.text);
        expect(file, equals("hello"));

        Loader.purgeResource("testdata.txt");
    });

    test("Multiple grouped requests", () async {
        final List<String> files = await Future.wait(<Future<String>>[
            Loader.getResource("testdata.txt", format:Formats.text),
            Loader.getResource("testdata.txt", format:Formats.text),
            Loader.getResource("testdata.txt", format:Formats.text),
        ]);

        expect(files, equals(<String>["hello", "hello", "hello"]));

        Loader.purgeResource("testdata.txt");
    });

    /*test("DataPack tests", () async {
        final Archive zip = await Loader.getResource("folderpack.zip");

        DataPack pack = new DataPack(zip);
    });*/

    test("Canonical resources", () async {
        final ImageElement img1 = await Loader.getResource("testimage.png");
        final ImageElement img2 = await Loader.getResource("testimage.png");

        final ImageElement img3 = await Loader.getResource("testimage.png", forceCanonical: true);
        final ImageElement img4 = await Loader.getResource("testimage.png", forceCanonical: true);

        expect(<bool>[(img1 != img2), (img3 == img4), (img1 != img3)], equals(<bool>[true,true,true]));

        Loader.purgeResource("testimage.png");
    });
}
