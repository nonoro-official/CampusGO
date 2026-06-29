import 'dart:io';
import 'package:http/http.dart' as http;

class PhotoUploader {
  static Future<bool> uploadImage(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://your-api-endpoint.com/upload'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
