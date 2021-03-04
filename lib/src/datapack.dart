import "package:archive/archive.dart";

class DataPack implements Comparable<DataPack> {
    static int _nextId = 0;

    final Archive archive;
    final Map<String, int> fileMap = <String, int>{};
    final int _id;
    final int priority;

    DataPack(Archive this.archive, {String? path, int this.priority = 1}) : this._id = _nextId++ {
        final List<ArchiveFile> files = this.archive.files;
        path ??= "";

        for (int i=0; i<files.length; i++) {
            final ArchiveFile file = files[i];
            fileMap["$path${file.name}"] = i;
        }

        //print(fileMap);
    }

    @override
    int compareTo(DataPack other) {
        final int compPriority = this.priority.compareTo(other.priority);

        return  compPriority == 0 ? this._id.compareTo(other._id) : compPriority;
    }
}