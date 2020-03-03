@TestOn("browser")

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
}
