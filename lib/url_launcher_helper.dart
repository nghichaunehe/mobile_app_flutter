import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

Future<bool> openUrl(String url) async {
  // Dùng url_launcher cho cả web và mobile
  final uri = Uri.parse(url);
  if (await url_launcher.canLaunchUrl(uri)) {
    await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
    return true;
  }
  return false;
}
