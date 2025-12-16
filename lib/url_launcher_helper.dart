import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

Future<bool> openUrl(String url) async {
  if (kIsWeb) {
    // Trên web, dùng window.open
    html.window.open(url, '_blank');
    return true;
  } else {
    // Trên mobile, dùng url_launcher
    final uri = Uri.parse(url);
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}
