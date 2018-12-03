import "dart:async";
import "dart:convert";

import "FileFormat.dart";

class JSONFormat extends StringFileFormat<Map<String, dynamic>> {
    static JsonEncoder _encoder = new JsonEncoder.withIndent("\t");
    static JsonDecoder _decoder = new JsonDecoder();

    @override
    String mimeType() => "application/json";

    @override
    Future<Map<String,dynamic>> read(String input) async {
        dynamic data =  _decoder.convert(input);
        if (!data is Map) {
            return <String,dynamic> { "data": data };
        }
        return data;
    }

    @override
    Future<String> write(Map<String,dynamic> data) async {
        return _encoder.convert(data);
    }

    @override
    String header() => "{";
}

class CSVFormat extends StringFileFormat<List<List<String>>> {

    /// Delimiter between values - feel free to change this before loading a file but remember the loader is async!
    String delimiter = ",";
    static final RegExp _linebreak = new RegExp(r"\r?\n");

    @override
    String mimeType() => "text/csv";

    @override
    Future<List<List<String>>> read(String input) async => input.split(_linebreak).map((String line) => line.split(delimiter));

    @override
    Future<String> write(List<List<String>> data) async => data.map((List<String> record) => record.join(delimiter)).join("\r\n");

    @override
    String header() => "";
}

class KeyPairFormat extends StringFileFormat<Map<String,dynamic>> {

    static CSVFormat _csv = new CSVFormat()..delimiter=":";

    dynamic _interpret(String val) {
        try {
            return int.parse(val);
        } catch(e) {
            try {
                return double.parse(val);
            } catch(e) {
                return val;
            }
        }
    }

    @override
    String mimeType() => "text/csv";

    @override
    Future<Map<String,String>> read(String input) async {
        List<List<String>> lines = await _csv.read(input);

        Map<String,dynamic> map = <String,dynamic>{};

        for (List<String> line in lines) {
            if(line.isEmpty) { continue; }
            if(line.length != 2) { throw new FormatException("Expected 2 values per line, got ${line.length}"); }

            map[line[0]] = _interpret(line[1]);
        }

        return map;
    }

    @override
    Future<String> write(Map<String,dynamic> data) async => data.keys.map((String key) => "$key:${data[key].toString()}").join("\r\n");

    @override
    String header() => "";
}