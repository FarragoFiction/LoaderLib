import "dart:async";

import 'package:LoaderLib/Loader.dart';

Future<Null> main() async {
    Loader.init();
    String file = await Loader.getResource("packages/LoaderLib/src/loader.dart", format: Formats.text);
    print(file);
}