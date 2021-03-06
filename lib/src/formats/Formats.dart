import "BasicFormats.dart";
import "FileFormat.dart";
import "ImageFormats.dart";
import "TextDataFormats.dart";
import "ZipFormat.dart";

export "FileFormat.dart";

abstract class Formats {
    static final TextFileFormat text = new TextFileFormat();
    static final RawBinaryFileFormat binary = new RawBinaryFileFormat();
    static final CSVFormat csv = new CSVFormat();
    static final JSONFormat json = new JSONFormat();
    static final KeyPairFormat keyPair = new KeyPairFormat();
    static final ZipFormat zip = new ZipFormat();
    static final RawZipFormat rawZip = new RawZipFormat();

    static final PngFileFormat png = new PngFileFormat();
    static final GifFileFormat gif = new GifFileFormat();
    static final JpegFileFormat jpeg = new JpegFileFormat();


    static final Map<String, ExtensionMappingEntry<dynamic,dynamic>> extensionMapping = <String, ExtensionMappingEntry<dynamic,dynamic>>{

        "txt":      mappingEntry(text),
        "vert":     mappingEntry(text, "x-shader/x-vertex"),
        "frag":     mappingEntry(text, "x-shader/x-fragment"),

        "csv":      mappingEntry(csv),

        "json":     mappingEntry(json),

        "zip":      mappingEntry(zip),
        "bundle":   mappingEntry(rawZip),

        "png":      mappingEntry(png),
        "jpg":      mappingEntry(jpeg),
        "jpeg":     mappingEntry(jpeg),
        "gif":      mappingEntry(gif),
    };

    static ExtensionMappingEntry<T,U> mappingEntry<T,U>(FileFormat<T,U> format, [String? mimeType]) {
        return new ExtensionMappingEntry<T,U>(format, mimeType);
    }

    static void addMapping<T,U>(FileFormat<T,U> format, String extension, [String? mimeType]) {
        extensionMapping[extension] = mappingEntry(format, mimeType);
        format.extensions.add(extension);
    }

    static ExtensionMappingEntry<T,U> getFormatEntryForExtension<T,U>(String extension) {
        if (extensionMapping.containsKey(extension)) {
            final ExtensionMappingEntry<T,U> mapping = extensionMapping[extension] as ExtensionMappingEntry<T,U>;
            final FileFormat<T,U> format = mapping.format;
            if (format is FileFormat<T,U>) {
                return mapping;
            }
            throw Exception("File format for extension .$extension does not match expected types.");
        }
        throw Exception("No file format found for extension .$extension");
    }

    static FileFormat<T,U> getFormatForExtension<T,U>(String extension) => getFormatEntryForExtension(extension).format as FileFormat<T,U>;
    static FileFormat<T,U> getFormatForFilename<T,U>(String filename) => getFormatForExtension(filename.split(".").last);
    static String? getMimeTypeForExtension(String extension) => getFormatEntryForExtension(extension).mimeType;
    static Iterable<String> getExtensionsForFormat(FileFormat<dynamic,dynamic> format) => extensionMapping.keys.where((String ext) => extensionMapping[ext]?.format == format);
}

class ExtensionMappingEntry<T,U> {
    FileFormat<T,U> format;
    String? mimeType;

    ExtensionMappingEntry(FileFormat<T,U> this.format, [String? this.mimeType]);
}