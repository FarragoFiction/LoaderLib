import "dart:async";
import "dart:convert";

import "package:csv/csv.dart";

import "FileFormat.dart";

class JSONFormat extends StringFileFormat<Map<String, dynamic>> {
    static const JsonEncoder _encoder = JsonEncoder.withIndent("\t");
    static const JsonDecoder _decoder = JsonDecoder();

    @override
    String mimeType() => "application/json";

    @override
    Future<Map<String,dynamic>> read(String input) async {
        final dynamic data =  _decoder.convert(input);
        if (!(data is Map)) {
            return <String,dynamic> { "data": data };
        }
        return data as Map<String,dynamic>;
    }

    @override
    Future<String> write(Map<String,dynamic> data) async {
        return _encoder.convert(data);
    }

    @override
    String header() => "{";
}

class CSVFormat extends StringFileFormat<List<List<dynamic>>> {

    String separator = ",";
    String delimiter = '"';
    String delimiterEnd = '"';
    String newline = "\r\n";

    static const CsvToListConverter _decoder = CsvToListConverter();
    static const ListToCsvConverter _encoder = ListToCsvConverter();

    @override
    String mimeType() => "text/csv";

    @override

    Future<List<List<dynamic>>> read(String input) async => _decoder.convert(input, fieldDelimiter: separator, textDelimiter: delimiter, textEndDelimiter: delimiterEnd, eol: newline);

    @override
    Future<String> write(List<List<dynamic>> data) async => _encoder.convert(data, fieldDelimiter: separator, textDelimiter: delimiter, textEndDelimiter: delimiterEnd, eol: newline);

    @override
    String header() => "";
}

class KeyPairFormat extends StringFileFormat<Map<String,dynamic>> {

    static final CSVFormat _csv = new CSVFormat()..separator=":";

    /*dynamic _interpret(String val) {
        try {
            return int.parse(val);
        } on Exception {
            try {
                return double.parse(val);
            } on Exception {
                return val;
            }
        }
    }*/
    //dynamic _interpret(String val) => int.tryParse(val) ?? double.tryParse(val) ?? val;

    @override
    String mimeType() => "text/csv";

    @override
    Future<Map<String,String>> read(String input) async {
        final List<List<dynamic>> lines = await _csv.read(input);

        final Map<String,dynamic> map = <String,dynamic>{};

        for (final List<dynamic> line in lines) {
            if(line.isEmpty) { continue; }
            if(line.length != 2) { throw new FormatException("Expected 2 values per line, got ${line.length}"); }

            map[line[0]] = line[1]; //_interpret(line[1]);
        }

        return map as Map<String,String>;
    }

    @override
    Future<String> write(Map<String,dynamic> data) async => data.keys.map((String key) => "$key:${data[key].toString()}").join("\r\n");

    @override
    String header() => "";
}