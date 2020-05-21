import 'package:test/test.dart';
import 'dart:math';

import 'sudoku.dart';

void main() {
  group('internal solver', () {
    test('no more open positions returns 9x9 array of dots', () {
      expect(
          placeRemainingDigits([]),
          allOf(hasLength(equals(9)), everyElement(hasLength(equals(9))),
              everyElement(everyElement(equals('.')))));
    });
    test('last digit gets placed', () {
      expect(
          placeRemainingDigits([
            OpenPosition(Point(0, 0), ['5'])
          ]),
          (result) => result[0][0] == '5');
    });
    test('solves 3 digits on row', () {
      expect(
          placeRemainingDigits([
            OpenPosition(Point(0, 0), ['5']),
            OpenPosition(Point(0, 4), ['2', '5', '7']),
            OpenPosition(Point(0, 8), ['2', '5'])
          ]),
          allOf(
              (result) => result[0][0] == '5',
              (result) => result[0][4] == '7',
              (result) => result[0][8] == '2'));
    });
    test('solves 3 digits on column', () {
      expect(
          placeRemainingDigits([
            OpenPosition(Point(1, 0), ['6', '7', '9']),
            OpenPosition(Point(5, 0), ['7']),
            OpenPosition(Point(6, 0), ['7', '9'])
          ]),
          allOf(
              (result) => result[1][0] == '6',
              (result) => result[5][0] == '7',
              (result) => result[6][0] == '9'));
    });
    test('solves 3 digits in block', () {
      expect(
          placeRemainingDigits([
            OpenPosition(Point(3, 2), ['4', '6']),
            OpenPosition(Point(4, 0), ['6']),
            OpenPosition(Point(5, 1), ['4', '6', '9'])
          ]),
          allOf(
              (result) => result[3][2] == '4',
              (result) => result[4][0] == '6',
              (result) => result[5][1] == '9'));
    });
    test('no remaining options returns null', () {
      expect(placeRemainingDigits([OpenPosition(Point(0, 0), [])]), isNull);
    });
    // A contradiction happens if '3' gets chosen from ['3', '5']
    test('contradiction is backtracked', () {
      expect(
          placeRemainingDigits([
            OpenPosition(Point(0, 0), ['3', '5']),
            OpenPosition(Point(0, 1), ['3', '4', '6']),
            OpenPosition(Point(0, 2), ['3', '4', '6']),
            OpenPosition(Point(0, 3), ['3', '4', '6'])
          ]),
          allOf(
              (result) => result[0][0] == '5',
              (result) => result[0][1] == '3',
              (result) => result[0][2] == '4',
              (result) => result[0][3] == '6'));
    });
  });

  test('input sudoku', () {
    var parsedInput = parseSudoku('''53.|.7.|...
      6..|195|...
      .98|...|.67
      -----------
      8..|.6.|..3
      4..|8.3|..1
      7..|.2.|..6
      -----------
      .6.|...|28.
      ...|419|..5
      ...|.8.|.79''');
    expect(parsedInput, hasLength(81));
    expect(parsedInput[0].position, equals(Point(0, 0)));
    expect(parsedInput[0].choices, equals(['5']));
    expect(parsedInput[18].position, equals(Point(2, 0)));
    expect(parsedInput[18].choices,
        equals(['1', '2', '3', '4', '5', '6', '7', '8', '9']));
    expect(parsedInput[19].position, equals(Point(2, 1)));
    expect(parsedInput[19].choices, equals(['9']));
  });

  test('fill in solved sudoku', () {
    expect(solveSudoku('''534|678|912
672|195|348
198|342|567
-----------
859|761|423
426|853|791
713|924|856
-----------
961|537|284
287|419|635
345|286|179
'''), equals('''534|678|912
672|195|348
198|342|567
-----------
859|761|423
426|853|791
713|924|856
-----------
961|537|284
287|419|635
345|286|179
'''));
  });

  test('solve sudoku', () {
    expect(solveSudoku('''53.|.7.|...
      6..|195|...
      .98|...|.67
      -----------
      8..|.6.|..3
      4..|8.3|..1
      7..|.2.|..6
      -----------
      .6.|...|28.
      ...|419|..5
      ...|.8.|.79'''), equals('''534|678|912
672|195|348
198|342|567
-----------
859|761|423
426|853|791
713|924|856
-----------
961|537|284
287|419|635
345|286|179
'''));
  });
}
