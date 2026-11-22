// The JavaScript semantics the templates rely on (lib/src/pdf/js.dart). The
// expected values are what Node 22 prints. Runs on the VM and in browsers.
import 'package:lifeastroapi/src/pdf/js.dart';
import 'package:lifeastroapi/src/pdf/locales.dart';
import 'package:test/test.dart';

void main() {
  test('String(n)', () {
    expect(jsNum(28.0), '28');
    expect(jsNum(-0.0), '0');
    expect(jsNum(2.5), '2.5');
    expect(jsNum(1e-7), '1e-7');
    expect(jsNum(0.000001), '0.000001');
    expect(jsNum(1e21), '1e+21');
    expect(jsNum(1e20), '100000000000000000000');
    expect(jsNum(double.nan), 'NaN');
    expect(jsNum(double.negativeInfinity), '-Infinity');
    // A JSON integer beyond 2^53 is a double in JS.
    expect(jsNum(int.parse('9007199254740993')), '9007199254740992');
  });

  test('String(v)', () {
    expect(jsStr(null), 'undefined');
    expect(jsStr([1, null, 2.0]), '1,,2');
    expect(jsStr({'a': 1}), '[object Object]');
  });

  test('toFixed', () {
    expect(toFixed(-0.0, 2), '0.00');
    expect(toFixed(-0.001, 2), '-0.00');
    expect(toFixed(0.125, 2), '0.13');
    expect(toFixed(1.005, 2), '1.00');
    expect(toFixed(2.675, 2), '2.67');
    expect(toFixed(-2.5, 0), '-3');
    expect(toFixed(5, 1), '5.0');
  });

  test('trim keeps U+0085 and strips the other Unicode spaces', () {
    final nel = String.fromCharCode(0x85);
    final spaces = String.fromCharCodes([0xa0, 0xfeff, 0x2028, 0x3000, 0x09]);
    expect(jsTrim('$nel x $nel'), '$nel x $nel');
    expect(jsTrim('${spaces}x$spaces'), 'x');
    expect(jsTrim(spaces), '');
  });

  test('Number(v)', () {
    expect(jsNumber(null), 0);
    expect(jsNumber(' 7 '), 7);
    expect(jsNumber('0x10'), 16);
    expect(jsNumber('0b11'), 3);
    expect(jsNumber(''), 0);
    expect(jsNumber(true), 1);
    expect(jsNumber('seven').isNaN, isTrue);
  });

  test('truthiness', () {
    for (final v in [null, false, 0, -0.0, double.nan, '']) {
      expect(truthy(v), isFalse, reason: '$v');
    }
    for (final v in [true, 1, '0', ' ', <int>[], <String, int>{}]) {
      expect(truthy(v), isTrue, reason: '$v');
    }
  });

  test('Object.keys order', () {
    expect(jsKeys({'b': 1, '10': 1, 'a': 1, '2': 1, '01': 1}),
        ['2', '10', 'b', 'a', '01']);
  });

  group('new Date(iso)', () {
    const valid = {
      '2026-03-01': '2026-03-01 00:00 UTC',
      '2026-03': '2026-03-01 00:00 UTC',
      '2026-02-30T10:00:00Z': '2026-03-02 10:00 UTC',
      '2026-03-01T24:00:00Z': '2026-03-02 00:00 UTC',
      '2026-03-01T01:20:30+05:30': '2026-02-28 19:50 UTC',
      '2026-03-01T10:20:30.123456789Z': '2026-03-01 10:20 UTC',
      '2026-03-01 10:20:30+0530': '2026-03-01 04:50 UTC',
    };
    valid.forEach((iso, shown) {
      test(iso, () => expect(formatGenerated(iso), shown));
    });

    test('jsRound: halves go up, and 0.49999999999999994 does not', () {
      expect(jsRound(2.5), 3);
      expect(jsRound(-2.5), -2);
      expect(jsRound(0.49999999999999994), 0);
      expect(jsRound(93.49999999999999), 93);
    });

    test('an ISO time without a zone is UTC, in any machine zone', () {
      for (final (iso, shown) in [
        ('2027-01-15T16:39:17', '2027-01-15 16:39 UTC'),
        ('2027-01-15T16:39', '2027-01-15 16:39 UTC'),
        ('2027-01-15 16:39', '2027-01-15 16:39 UTC'),
        ('2027-01-15t16:39:17.5', '2027-01-15 16:39 UTC'),
        ('2027-01-15T23:59:59.999', '2027-01-15 23:59 UTC'),
      ]) {
        expect(formatGenerated(iso), shown);
      }
      expect(formatGenerated('2027-13-15T16:39'), '2027-13-15T16:39',
          reason: 'printed as it came, without the Z');
    });

    const invalid = [
      '2026-13-01',
      '2026-03-32',
      '2026-03-00',
      '20260301',
      '2026-03-01T24:30:00Z',
      '2026-03-01T10:20:60Z',
      '2026-03-01T10:20:30+05',
    ];
    for (final iso in invalid) {
      test('$iso is printed as it is', () {
        expect(formatGenerated(iso), iso);
      });
    }
  });

  test('a Part heading is recognised in every script', () {
    for (final title in [
      'Part 1: Birth',
      'भाग 2: दशा',
      'భాగం 3: దశ',
      'பகுதி 1: ஜாதகம்',
      'ಭಾಗ 1: ಜಾತಕ',
      'ഭാഗം 1: ജാതകം',
      'ભાગ 1: કુંડળી',
      'ভাগ 1: কুণ্ডলী',
      'ਭਾਗ 1: ਕੁੰਡਲੀ',
    ]) {
      expect(partPrefixRe.hasMatch(title), isTrue, reason: title);
    }
    expect(partPrefixRe.hasMatch('ਭਾਗਸ਼ਾਲੀ ਰਤਨ'), isFalse);
  });
}
