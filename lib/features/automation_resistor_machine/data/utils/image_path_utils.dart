const String _defaultImageHost = 'https://10.220.130.117';
const String _defaultImageRoot = '/newweb';

String normalizeResistorMachineImagePath(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final sanitized = trimmed.replaceAll('\\', '/');

  final Uri? parsed = Uri.tryParse(sanitized);
  if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
    return parsed.toString();
  }

  if (sanitized.startsWith('//')) {
    return 'https:$sanitized';
  }

  final String withoutLeadingSlashes = sanitized.startsWith('//')
      ? sanitized.substring(2)
      : sanitized.startsWith('/')
          ? sanitized.substring(1)
          : sanitized;

  if (withoutLeadingSlashes.startsWith('10.220.130.117')) {
    return 'https://$withoutLeadingSlashes';
  }

  final String relativePath = sanitized.startsWith('/')
      ? sanitized
      : '/$sanitized';

  if (relativePath.startsWith('$_defaultImageRoot/')) {
    return '$_defaultImageHost$relativePath';
  }

  return '$_defaultImageHost$_defaultImageRoot$relativePath';
}
