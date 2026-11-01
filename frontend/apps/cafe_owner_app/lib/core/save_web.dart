import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void saveBytes(List<int> bytes, String filename, String mime) {
  final blob = web.Blob([Uint8List.fromList(bytes).toJS].toJS, web.BlobPropertyBag(type: mime));
  final url = web.URL.createObjectURL(blob);
  (web.document.createElement('a') as web.HTMLAnchorElement)
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
}
