import 'dart:async';
import 'dart:html';
import "dart:typed_data";

import "package:archive/archive.dart";
import "package:CommonLib/CommonLib.dart";

import "formats/Formats.dart";
import "manifest/BundleManifest.dart";
import "resource.dart";

export "resource.dart";

abstract class Loader {
    static bool _initialised = false;
    static BundleManifest manifest;
    static Map<String, Resource<dynamic>> _resources = <String, Resource<dynamic>>{};
    static RegExp _slash = new RegExp("[\\/]");

    /// The manifest is now optional and if you don't call to load it explicitly, it's totally ignored.
    static bool _usingManifest = false;

    static void init() {
        if (_initialised) { return; }
        _initialised = true;

        Formats.init();
    }

    static Future<T> getResource<T>(String path, {FileFormat<T, dynamic> format, bool bypassManifest = false, bool absoluteRoot = false}) async {
        init();
        if (_resources.containsKey(path)) {
            Resource<dynamic> res = _resources[path];
            if (res is Resource<T>) {
                if (res.object != null) {
                    return res.object;
                } else {
                    return res.addListener();
                }
            } else {
                throw "Requested resource ($path) is an unexpected type: ${res.object.runtimeType}.";
            }
        } else {
            if (_usingManifest && !bypassManifest) {
                if (manifest == null) {
                    await loadManifest();
                }

                String bundle = manifest.getBundleForFile(path);

                if (bundle != null) {
                    _loadBundle(bundle);
                    return _createResource(path).addListener();
                }
            }
            return _load(path, format: format, absoluteRoot: absoluteRoot);
        }
    }

    static Future<Null> loadManifest() async {
        _usingManifest = true;
        manifest = await Loader.getResource("manifest/manifest.txt", format: Formats.manifest, bypassManifest: true);
    }

    static Resource<T> _createResource<T>(String path) {
        if (!_resources.containsKey(path)) {
            _resources[path] = new Resource<T>(path);
        }
        return _resources[path];
    }

    static Future<T> _load<T>(String path, {FileFormat<T, dynamic> format = null, bool absoluteRoot = false}) {
        if(_resources.containsKey(path)) {
            throw "Resource $path has already been requested for loading";
        }

        if (format == null) {
            String extension = path.split(".").last;
            format = Formats.getFormatForExtension(extension);
        }

        Resource<T> res = _createResource(path);

        format.requestObjectFromUrl(_getFullPath(path, absoluteRoot))..then((T item) => res.populate(item));

        return res.addListener();
    }

    /// Sets a resource at a specified path to an object, does not load a file
    static void assignResource<T>(T object, String path) {
        _createResource(path).object = object;
    }

    /// Removes a resource from the listings, and completes any waiting gets with an error state
    static void purgeResource(String path) {
        if (_resources.containsKey(path)) {
            Resource<dynamic> r = _resources[path];
            for(Completer<dynamic> c in r.listeners) {
                if (!c.isCompleted) {
                    c.completeError("Resource purged");
                }
            }
        }
        _resources.remove(path);
    }

    static Future<bool> _loadBundle(String path) async {
        Archive bundle = await Loader.getResource("$path.bundle", bypassManifest: true);

        String dir = path.substring(0, path.lastIndexOf(_slash));

        for (ArchiveFile file in bundle.files) {
            String extension = file.name.split(".").last;
            FileFormat<dynamic, dynamic> format = Formats.getFormatForExtension(extension);

            String fullname = "$dir/${file.name}";

            Resource<dynamic> res = _createResource(fullname);

            Uint8List data = file.content as Uint8List;

            format.read(await format.fromBytes(data.buffer)).then(res.populate);
        }

        return true;
    }

    // JS loading extra special dom stuff

    static Map<String, ScriptElement> _loadedScripts = <String, ScriptElement>{};

    static Future<ScriptElement> loadJavaScript(String path, [bool absoluteRoot = false]) async {
        if (_loadedScripts.containsKey(path)) {
            return _loadedScripts[path];
        }
        Completer<ScriptElement> completer = new Completer<ScriptElement>();

        ScriptElement script = new ScriptElement();
        document.head.append(script);
        script.onLoad.listen((Event e) => completer.complete(script));
        script.src = _getFullPath(path, absoluteRoot);

        return completer.future;
    }

    static String _getFullPath(String path, [bool absoluteRoot = false]) {
        // treat leading slashes as absolute root anyway
        if (path.startsWith("/")) {
            absoluteRoot = true;
            path = path.substring(1);
        }

        if (absoluteRoot) {
            String abspath = "${window.location.protocol}//${window.location.host}/$path";
            return abspath;
        }
        return PathUtils.adjusted(path);
    }
}

class Asset<T> {
    T item;
    String path;

    Asset(String this.path);
    Asset.direct(T this.item);

    Future<T> getAsset() async {
        if (this.item != null) {
            return this.item;
        }
        else if (this.path != null) {
            return await Loader.getResource(this.path);
        }
        return null;
    }
}