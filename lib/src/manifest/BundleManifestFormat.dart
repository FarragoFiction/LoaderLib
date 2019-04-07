import "dart:async";

import "../formats/FileFormat.dart";

import "BundleManifest.dart";

class BundleManifestFormat extends StringFileFormat<BundleManifest> {

    @override
    String mimeType() => "application/octet-stream"; // hopefully this will discourage caches of the manifest

    @override
    Future<BundleManifest> read(String input) async {
        final List<String> lines = input.split("\n");

        final BundleManifest out = new BundleManifest();

        String bundle;

        for (int i=1; i<lines.length; i++) {
            final String line = lines[i];

            if (line.trim().isEmpty) {
                // empty line, not in a block
                bundle = null;
            } else {
                if (bundle == null) {
                    // first non-empty, set tar
                    bundle = line.trim();
                } else {
                    // subsequent non-empty, add to category
                    out.add(line.trim(), bundle);
                }
            }
        }

        return out;
    }

    @override
    Future<String> write(BundleManifest data) async {
        final StringBuffer sb = new StringBuffer()
        ..writeln(header())
        ..writeln();

        for (final String bundle in data.bundleFiles) {
            sb.writeln(bundle);
            for (final String file in data.getFilesInBundle(bundle)) {
                sb.writeln("\t$file");
            }
            sb.writeln();
        }

        return sb.toString();
    }

    @override
    String header() => "SBURBSim Bundle Manifest";
}
