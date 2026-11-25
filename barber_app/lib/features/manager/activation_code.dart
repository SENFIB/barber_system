class ActivationParts {
  const ActivationParts(this.license, this.url);

  final String license;
  final String? url;
}

final RegExp _kFullUrl =
    RegExp(r'^https://script\.google\.com/macros/s/[A-Za-z0-9_\-]+/exec$');
final RegExp _kIdOnly = RegExp(r'^[A-Za-z0-9_\-]{40,}$');

ActivationParts splitActivation(String raw) {
  final tokens = raw
      .trim()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  String? url;
  final rest = <String>[];
  for (final t in tokens) {
    if (url == null && _kFullUrl.hasMatch(t)) {
      url = t;
    } else if (url == null && _kIdOnly.hasMatch(t)) {
      url = 'https://script.google.com/macros/s/$t/exec';
    } else {
      rest.add(t);
    }
  }
  return ActivationParts(rest.isEmpty ? '' : rest.first, url);
}
