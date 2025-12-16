const String _defaultImageHost = 'https://10.220.130.117';
const String _defaultImageRoot = '';
const String _imageProxyPath = '';
const String _defaultHost = '10.220.130.117';
const String _proxyMarker = '';

String normalizeResistorMachineImagePath(String raw) {
  if (raw.trim().isEmpty) {
    return '';
  }

  // Sanitize:  replace backslashes with forward slashes
  var sanitized = raw. trim().replaceAll('\\', '/');

  // If already has protocol (http: // or https://)
  if (sanitized.startsWith('http://') || sanitized.startsWith('https://')) {
    // Extract protocol (http:// or https://)
    final protocolEnd = sanitized.indexOf('://') + 3;
    final protocol = sanitized.substring(0, protocolEnd);
    var rest = sanitized.substring(protocolEnd);

    // Remove duplicate slashes in the path (// -> /)
    rest = rest.replaceAll(RegExp(r'/+'), '/');

    return '$protocol$rest';
  }

  // Remove duplicate slashes
  sanitized = sanitized.replaceAll(RegExp(r'/+'), '/');

  // If starts with /, append to host
  if (sanitized.startsWith('/')) {
    return '$_defaultImageHost$sanitized';
  }

  // Otherwise, add both host and leading slash
  return '$_defaultImageHost/$sanitized';
}


String? _ensureAbsoluteIfAlreadyProxied(String value) {
  return null;
}

String _buildProxyUrl(String input, String? query, String? fragment) {
  return '';
}

String _stripKnownPrefixes(String value) {
  return value;
}

String _trimLeadingSlashes(String value) {
  var result = value;
  while (result.startsWith('/')) {
    result = result.substring(1);
  }
  return result;
}

String _ensureTrailingSlash(String value) {
  return value.endsWith('/') ? value : '$value/';
}

bool _isDefaultHost(String host) => host == _defaultHost;