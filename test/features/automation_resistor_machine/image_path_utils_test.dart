import 'package:flutter_test/flutter_test.dart';

import 'package:smart_office_aiot/features/automation_resistor_machine/data/utils/image_path_utils.dart';

void main() {
  group('normalizeResistorMachineImagePath', () {
    test('returns empty when input is empty', () {
      expect(normalizeResistorMachineImagePath(''), isEmpty);
      expect(normalizeResistorMachineImagePath('   '), isEmpty);
    });

    test('keeps absolute urls intact', () {
      const url = 'https://10.220.130.117/newweb/Upload/image.png';
      expect(normalizeResistorMachineImagePath(url), url);
    });

    test('normalizes UNC windows paths', () {
      const raw = r"\\\\10.220.130.117\\newweb\\Upload\\image.png";
      expect(
        normalizeResistorMachineImagePath(raw),
        'https://10.220.130.117/newweb/Upload/image.png',
      );
    });

    test('normalizes protocol relative paths', () {
      const raw = '//10.220.130.117/newweb/Upload/image.png';
      expect(
        normalizeResistorMachineImagePath(raw),
        'https://10.220.130.117/newweb/Upload/image.png',
      );
    });

    test('normalizes simple relative paths', () {
      const raw = 'Upload/image.png';
      expect(
        normalizeResistorMachineImagePath(raw),
        'https://10.220.130.117/newweb/Upload/image.png',
      );
    });

    test('normalizes paths that already include newweb prefix', () {
      const raw = 'newweb/Upload/image.png';
      expect(
        normalizeResistorMachineImagePath(raw),
        'https://10.220.130.117/newweb/Upload/image.png',
      );
    });
  });
}
