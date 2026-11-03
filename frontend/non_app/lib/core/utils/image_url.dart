import '../constants/api_constants.dart';

String? resolveImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) return null;

  final value = url.trim();

  if (value.startsWith('http://') || value.startsWith('https://')) return value;

  final base = ApiConstants.baseUrl.endsWith('/')
      ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
      : ApiConstants.baseUrl;

  return value.startsWith('/') ? '$base$value' : '$base/$value';
}