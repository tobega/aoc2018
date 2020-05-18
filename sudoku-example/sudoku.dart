import 'dart:core';
import 'dart:math';

class OpenPosition {
  Point position;
  List<String> choices;

  OpenPosition(this.position, this.choices);

  OpenPosition withConstraint(Point where, String symbol) {
    var choicesCopy = List.of(choices);
    if (where.x == position.x // same row
        || where.y == position.y // same column
        || (where.x ~/ 3 == position.x ~/3 && where.y ~/ 3 == position.y ~/ 3) // same block
    ) {
      choicesCopy.remove(symbol);
    }
    return OpenPosition(position, choicesCopy);
  }
}

List<List<String>> placeRemainingDigits(List<OpenPosition> remaining) {
  if (remaining.isEmpty) {
    return List.generate(
        9, (index) => List.filled(9, '.', growable: false), growable: false);
  }
  var bestOpen = remaining.reduce((a, b) => b.choices.length < a.choices.length ? b : a);
  remaining.remove(bestOpen);
  while (bestOpen.choices.isNotEmpty) {
    var chosenDigit = bestOpen.choices.removeAt(0);
    var result = placeRemainingDigits(remaining.map((e) =>
        e.withConstraint(bestOpen.position, chosenDigit)).toList());
    if (result != null) {
      result[bestOpen.position.x][bestOpen.position.y] = chosenDigit;
      return result;
    }
  }
  return null;
}

List<OpenPosition> parseSudoku(String input) {
  List<OpenPosition> positions = List();
  var digits = List.generate(9, (index) => (index + 1).toString());
  var meaningfulInput = digits.followedBy(['.']);
  input.split('').where((element) => meaningfulInput.contains(element))
    .toList().asMap().forEach((i, s) {
      positions.add(OpenPosition(Point(i ~/ 9, i % 9),
        digits.contains(s) ? [s] : List.of(digits)));
  });
  return positions;
}

String solveSudoku(String input) {
  List<List<String>> solution = placeRemainingDigits(parseSudoku(input));
  if (solution == null) {
    return 'No solution found';
  }
  List<String> rows = solution.map((e) =>
    '${e.sublist(0,3).join()}|${e.sublist(3,6).join()}|${e.sublist(6,9).join()}')
  .toList();
  return rows.sublist(0,3).followedBy(['-'*11])
      .followedBy(rows.sublist(3,6)).followedBy(['-'*11])
      .followedBy(rows.sublist(6,9)).join('\n') + '\n';
}