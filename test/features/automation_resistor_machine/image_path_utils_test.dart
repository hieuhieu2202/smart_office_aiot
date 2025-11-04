import 'package:flutter_test/flutter_test.dart';

import 'package:smart_office_aiot/features/automation_resistor_machine/data/utils/image_path_utils.dart';

void main() {
  group('normalizeResistorMachineImagePath', () {
    const proxyBase = 'https://10.220.130.117/newweb/api/image/raw';

    test('returns empty when input is empty', () {
      expect(normalizeResistorMachineImagePath(''), isEmpty);
      expect(normalizeResistorMachineImagePath('   '), isEmpty);
    });

    test('wraps default host absolute urls with proxy endpoint', () {
      const url = 'https://10.220.130.117/newweb/Upload/image.png';
      expect(
        normalizeResistorMachineImagePath(url),
        '$proxyBase/Upload/image.png',
      );
    });

    test('leaves unrelated absolute urls untouched', () {
      const url = 'https://example.com/assets/image.png';
      expect(normalizeResistorMachineImagePath(url), url);
    });

    test('normalizes UNC windows paths', () {
      const raw = r"\\\\10.220.130.117\\newweb\\Upload\\image.png";
      expect(
        normalizeResistorMachineImagePath(raw),
        '$proxyBase/Upload/image.png',
      );
    });

    test('normalizes protocol relative paths', () {
      const raw = '//10.220.130.117/newweb/Upload/image.png';
      expect(
        normalizeResistorMachineImagePath(raw),
        '$proxyBase/Upload/image.png',
      );
    });

    test('normalizes simple relative paths', () {
      const raw = 'Upload/image.png';
      expect(
        normalizeResistorMachineImagePath(raw),
        '$proxyBase/Upload/image.png',
      );
    });

    test('normalizes paths that already include newweb prefix', () {
      const raw = 'newweb/Upload/image.png';
      expect(
        normalizeResistorMachineImagePath(raw),
        '$proxyBase/Upload/image.png',
      );
    });

    test('encodes spaces within path segments', () {
      const raw = 'Upload/Test Folder/Image 01.png';
      expect(
        normalizeResistorMachineImagePath(raw),
        '$proxyBase/Upload/Test%20Folder/Image%2001.png',
      );
    });

    test('keeps already proxied paths intact while ensuring absolute url', () {
      const raw = 'api/image/raw/Upload/image.png';
      expect(
        normalizeResistorMachineImagePath(raw),
        '$proxyBase/Upload/image.png',
      );

      const absolute = 'https://10.220.130.117/newweb/api/image/raw/Upload/image.png';
      expect(normalizeResistorMachineImagePath(absolute), absolute);
    });
  });
}
