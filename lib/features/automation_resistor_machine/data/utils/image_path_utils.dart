const String _defaultImageHost = 'https://10.220.130.117';
const String _defaultImageRoot = '';
const String _imageProxyPath = '/api/image/raw';
const String _defaultHost = '10.220.130.117';
const String _proxyMarker = '/api/image/raw/';

String normalizeResistorMachineImagePath(String raw) {
  final sanitized = raw.trim().replaceAll('\\', '/');
  if (sanitized.isEmpty) {
    return '';
  }

  final alreadyProxied = _ensureAbsoluteIfAlreadyProxied(sanitized);
  if (alreadyProxied != null) {
    return alreadyProxied;
  }

  final Uri? parsed = Uri.tryParse(sanitized);
  if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
    if (_isDefaultHost(parsed.host)) {
      return _buildProxyUrl(parsed.path, parsed.query, parsed.fragment);
    }
    return parsed.toString();
  }

  if (sanitized.startsWith('//')) {
    final Uri? protoUri = Uri.tryParse('https:$sanitized');
    if (protoUri != null && protoUri.hasScheme && protoUri.host.isNotEmpty) {
      if (_isDefaultHost(protoUri.host)) {
        return _buildProxyUrl(protoUri.path, protoUri.query, protoUri.fragment);
      }
      return protoUri.toString();
    }
    return 'https:$sanitized';
  }

  return _buildProxyUrl(sanitized, null, null);
}

String? _ensureAbsoluteIfAlreadyProxied(String value) {
  final String normalized = value.startsWith('http://') || value.startsWith('https://')
      ? value
      : value.startsWith('/')
          ? value
          : '/$value';

  if (!normalized.toLowerCase().contains(_proxyMarker)) {
    return null;
  }

  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return normalized;
  }

  final String path = normalized.startsWith(_defaultImageRoot)
      ? normalized
      : '$_defaultImageRoot$normalized';
  return '$_defaultImageHost$path';
}

String _buildProxyUrl(String input, String? query, String? fragment) {
  final Uri? parsed = Uri.tryParse(input);
  final String path = parsed?.path.isNotEmpty == true ? parsed!.path : input;
  final String stripped = _stripKnownPrefixes(path);
  if (stripped.isEmpty) {
    return '';
  }

  final Iterable<String> segments = stripped
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .map(Uri.encodeComponent);

  final String base = _ensureTrailingSlash('$_defaultImageHost$_imageProxyPath');
  final StringBuffer buffer = StringBuffer(base)
    ..writeAll(segments, '/');

  final String effectiveQuery = (parsed?.query.isNotEmpty == true)
      ? parsed!.query
      : (query ?? '');
  if (effectiveQuery.isNotEmpty) {
    buffer
      ..write('?')
      ..write(effectiveQuery);
  }

  final String effectiveFragment = (parsed?.fragment.isNotEmpty == true)
      ? parsed!.fragment
      : (fragment ?? '');
  if (effectiveFragment.isNotEmpty) {
    buffer
      ..write('#')
      ..write(effectiveFragment);
  }

  return buffer.toString();
}

String _stripKnownPrefixes(String value) {
  String working = value;

  if (working.startsWith('http://') || working.startsWith('https://')) {
    final Uri? uri = Uri.tryParse(working);
    if (uri != null) {
      working = uri.path;
    }
  }

  if (working.startsWith(_defaultImageHost)) {
    working = working.substring(_defaultImageHost.length);
  }

  if (working.startsWith('//')) {
    working = working.substring(2);
  }

  if (working.startsWith(_defaultHost)) {
    working = working.substring(_defaultHost.length);
  }

  working = _trimLeadingSlashes(working);

  final String rootWithoutSlash =
      _defaultImageRoot.startsWith('/') ? _defaultImageRoot.substring(1) : _defaultImageRoot;
  if (rootWithoutSlash.isNotEmpty &&
      working.toLowerCase().startsWith(rootWithoutSlash.toLowerCase())) {
    working = working.substring(rootWithoutSlash.length);
  }

  return _trimLeadingSlashes(working);
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
