@TestOn("browser")

//import "dart:async";

import 'package:LoaderLib/Loader.dart';
import 'package:test/test.dart';

void main() {
    test("Package Path Resolution", () async {
        final String file =await Loader.getResource("package:LoaderLib/src/loader.dart", format: Formats.text);
        expect(file, null);
    });
}
