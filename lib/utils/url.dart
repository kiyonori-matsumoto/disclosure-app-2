import 'package:url_launcher/url_launcher.dart';

launchURL(String url) async {
  final urlInstance = Uri.parse(url);
  try {
    if (await canLaunchUrl(urlInstance)) {
      await launchUrl(urlInstance);
    } else {
      throw 'Could not launch $url';
    }
  } catch (e) {
    print(e);
    throw e;
  }
}
