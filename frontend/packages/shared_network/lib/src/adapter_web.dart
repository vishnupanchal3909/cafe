import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

// Sends the HttpOnly refresh cookie on cross-origin API calls.
void configureAdapter(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
}
