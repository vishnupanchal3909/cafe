import 'package:url_launcher/url_launcher.dart';

void openExternal(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
