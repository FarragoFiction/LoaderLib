import 'dart:async';
import 'dart:collection';
import 'dart:html';

import "package:archive/archive.dart";
import "package:CommonLib/Utility.dart";

import "datapack.dart";
import "exceptions.dart";
import "formats/Formats.dart";
import "resource.dart";

export "resource.dart";

abstract class Loader {
    static final Map<String, Resource<dynamic>> _resources = <String, Resource<dynamic>>{};
    static final RegExp _slash = new RegExp(r"[\/]");
    static final RegExp _protocol = new RegExp(r"\w+:\/\/");

    static final StreamController<LoaderEvent> _eventBus = new StreamController<LoaderEvent>.broadcast();
    Stream<LoaderEvent> get eventBus => _eventBus.stream;

    static final SplayTreeSet<DataPack> _dataPacks = new SplayTreeSet<DataPack>();
    static final Map<String, DataPack> _dataPackFileMap = <String, DataPack>{};

    static Future<T> getResource<T>(String path, {FileFormat<T, dynamic> format, bool bypassManifest = false, bool absoluteRoot = false}) async {
        if (_resources.containsKey(path)) {
            final Resource<dynamic> res = _resources[path];
            //if (res is Resource<T>) {
                if (res.object != null) {
                    return res.object;
                } else {
                    return res.addListener();
                }
            //} else {
            //    throw "Requested resource ($path) is an unexpected type: ${res.object.runtimeType}.";
            //}
        } else {
            return _load(path, format: format, absoluteRoot: absoluteRoot);
        }
    }

    static Future<DataPack> loadDataPack(String filename, {String path, int priority = 1}) async {
        final Archive zip = await getResource(filename, format: Formats.zip);
        return mountDataPack(zip, path: path, priority: priority);
    }

    static DataPack mountDataPack(Archive zip, {String path, int priority = 1}) {
        final DataPack pack = new DataPack(zip, path: path, priority: priority);
        _dataPacks.add(pack);

        for (final String filename in pack.fileMap.keys) {
            purgeResource(filename);
        }

        _recalculateFileMap();

        _eventBus.add(new LoaderEvent(LoaderEventType.mount, pack.fileMap.keys.toSet()));

        return pack;
    }

    static void unmountDataPack(DataPack pack){
        _dataPacks.remove(pack);

        for (final String filename in pack.fileMap.keys) {
            purgeResource(filename);
        }

        _recalculateFileMap();

        _eventBus.add(new LoaderEvent(LoaderEventType.unmount, pack.fileMap.keys.toSet()));
    }

    static void unmountAllDataPacks() {
        final Set<String> filenames = _dataPackFileMap.keys.toSet();

        _dataPacks.clear();
        _recalculateFileMap();

        for (final String filename in filenames) {
            purgeResource(filename);
        }

        _eventBus.add(new LoaderEvent(LoaderEventType.unmount, filenames));
    }

    static void _recalculateFileMap() {
        _dataPackFileMap.clear();
        for (final DataPack pack in _dataPacks) {
            for (final String filename in pack.fileMap.keys) {
                if (!_dataPackFileMap.containsKey(filename)) {
                    _dataPackFileMap[filename] = pack;
                }
            }
        }
    }

    static Resource<T> _createResource<T>(String path) {
        if (!_resources.containsKey(path)) {
            _resources[path] = new Resource<T>(path);
        }
        return _resources[path];
    }

    static Future<T> _load<T>(String path, {FileFormat<T, dynamic> format, bool absoluteRoot = false}) async {
        if(_resources.containsKey(path)) {

            // I guess we can put this check here too to eliminate the problem... I guess this makes sense?
            final Resource<dynamic> res = _resources[path];
            //if (res is Resource<T>) { // forget the type check for now until a better solution is implemented
                if (res.object != null) {
                    return res.object;
                } else {
                    return res.addListener();
                }
            //} else {
            //    throw "Requested resource ($path) is an unexpected type: ${res.object.runtimeType}.";
            //}

            //throw "Resource $path has already been requested for loading";
        }

        if (format == null) {
            final String extension = path.split(".").last;
            format = Formats.getFormatForExtension(extension);
        }

        final Resource<T> res = _createResource(path);

        format.requestObjectFromUrl(_getFullPath(path, absoluteRoot))
            .then(res.populate)
            .catchError(_handleResourceError(res));

        return res.addListener();
    }

    /// Sets a resource at a specified path to an object, does not load a file
    static void assignResource<T>(T object, String path) {
        _createResource(path).object = object;
    }

    /// Removes a resource from the listings, and completes any waiting gets with an error state
    static void purgeResource(String path) {
        if (_resources.containsKey(path)) {
            final Resource<dynamic> r = _resources[path];
            for(final Completer<dynamic> c in r.listeners) {
                if (!c.isCompleted) {
                    c.completeError("Resource purged");
                }
            }
        }
        _resources.remove(path);
    }

    // JS loading extra special dom stuff

    static final Map<String, ScriptElement> _loadedScripts = <String, ScriptElement>{};

    static Future<ScriptElement> loadJavaScript(String path, [bool absoluteRoot = false]) async {
        if (_loadedScripts.containsKey(path)) {
            return _loadedScripts[path];
        }
        final Completer<ScriptElement> completer = new Completer<ScriptElement>();

        final ScriptElement script = new ScriptElement();
        document.head.append(script);
        script.onLoad.listen((Event e) => completer.complete(script));
        script.src = _getFullPath(path, absoluteRoot);

        return completer.future;
    }

    static String _getFullPath(String path, [bool absoluteRoot = false]) {
        if (path.startsWith(_protocol)) { // if this is a whole-ass URL just let it go direct
            return path;
        }
        
        // resolve package based urls... this isn't strictly necessary but it's nice
        if (path.startsWith("package:")) {
            path = "/packages/${path.substring(8)}";
        } else if (path.startsWith("/")) { // treat leading slashes as absolute root anyway
            absoluteRoot = true;
            path = path.substring(1);
        }

        if (absoluteRoot) {
            final String abspath = "${window.location.protocol}//${window.location.host}/$path";
            return abspath;
        }
        return PathUtils.adjusted(path);
    }

    static Element loadButton<T,U>(FileFormat<T,U> format, LoadButtonCallback<T> callback, {bool multiple = false, String caption = "Load file"}) {
        return FileFormat.loadButton<T, U>(format, callback, multiple: multiple, caption: caption);
    }

    static Element saveButton<T,U>(FileFormat<T,U> format, Generator<T> objectGetter, {String caption = "Save file", Generator<String> filename = FileFormat.defaultFilename}) {
        return FileFormat.saveButton<T, U>(format, objectGetter, caption: caption, filename: filename);
    }

    static Lambda<dynamic> _handleResourceError<T>(Resource<T> resource) {
        return (dynamic error) {
            resource.error(new LoaderException("Could not load ${resource.path}", error));
            purgeResource(resource.path);
        };
    }

    static _destroy() {
        _eventBus.close();
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
            return Loader.getResource(this.path);
        }
        return null;
    }
}

enum LoaderEventType {
    mount,
    unmount,
}

class LoaderEvent {
    final LoaderEventType type;
    final Set<String> files;

    const LoaderEvent(LoaderEventType this.type, Set<String> this.files);
}