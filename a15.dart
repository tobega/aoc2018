import 'dart:io';
import 'dart:math';

class Grid {
  List<List<Square>> rows = List();

  Square get(int row, int col) {
    return rows[row][col];
  }

  int nextRowNo() {
    return rows.length;
  }

  addRow(List<Square> row) {
    rows.add(row);
  }

  Grid copy() {
    Grid c = Grid();
    rows.forEach((r) => c.addRow(
        List.of(r.map((s) => s.copy(c)))));
    return c;
  }
}

enum Direction {up, left, right, down}

abstract class Square {

  Being occupant;

  Map<Direction, Square> neighbours() => Map();

  @override
  operator < (Square s) {
    if (runtimeType != Cavern || s.runtimeType != Cavern) return null;
    Cavern a = this as Cavern;
    Cavern c = s as Cavern;
    return a.row < c.row || (a.row == c.row && a.col < c.col);
  }

  copy(Grid newGrid);
}

class Rock extends Square {
  @override
  copy(Grid newGrid) {
    return this;
  }
}

class Cavern extends Square {
  final int row;
  final int col;
  final Grid grid;

  Cavern(this.row, this.col, this.grid);

  @override
  Map<Direction, Square> neighbours() {
    return {
      Direction.up: grid.get(row - 1, col),
      Direction.left: grid.get(row, col - 1),
      Direction.right: grid.get(row, col + 1),
      Direction.down: grid.get(row + 1, col)};
  }

  @override
  String toString() {
    return runtimeType.toString() + '(' + row.toString() + ', ' + col.toString() + '): {' + occupant.runtimeType.toString() + '}';
  }

  @override
  copy(Grid newGrid) {
    return Cavern(row, col, newGrid);
  }
}

abstract class Being {
  Cavern square;
  int hitPoints = 200;
  int attackValue = 3;

  Being(this.square);

  Type enemy();

  bool takeTurn() {
    bool couldMove = true;
    if (!inRange(square)) couldMove = move();
    if (couldMove) strike();
    return couldMove;
  }

  bool move() {
    Set<Square> visited = Set.of([square]);
    Map<Square, Direction> atDistance = square.neighbours()
        .map((Direction d, Square s) => MapEntry(s, d));
    atDistance.removeWhere((Square s, Direction d) => s is Rock || s.occupant != null);
    while (atDistance.isNotEmpty) {
      var possibleTargets = atDistance.keys
          .where((s) => inRange(s));
      var target = possibleTargets.isEmpty? null : possibleTargets
          .reduce((a,b) => b < a ? b : a);
      if (target != null) {
        square.occupant = null;
        square = square.neighbours()[atDistance[target]];
        square.occupant = this;
        return true;
      }
      visited.addAll(atDistance.keys);
      Map<Square, Direction> nextDistance = Map();
      atDistance.forEach((Square origin, Direction start) {
        origin.neighbours().values.where((s) => !visited.contains(s) && !(s is Rock) && s.occupant == null)
            .forEach((s) {
          nextDistance.update(s, (d) => d.index < start.index ? d : start, ifAbsent: () => start);
        });
      });
      atDistance = nextDistance;
    }
    return false;
  }

  bool inRange(Square s) {
    return s.neighbours().values.any(containsEnemy);
  }

  bool containsEnemy(Square s) => enemy() == s.occupant?.runtimeType;

  void strike() {
    var enemiesInRange = square.neighbours().values.where(containsEnemy)
      .map((s) => s.occupant);
    var enemyInRange = enemiesInRange.isEmpty ? null :
        enemiesInRange.reduce((a, b) {
          if (b.hitPoints < a.hitPoints) return b;
          if (a.hitPoints < b.hitPoints) return a;
          if (b.square < a.square) return b;
          return a;
        });
    if (enemyInRange != null) enemyInRange.hit(attackValue);
  }

  void hit(int attackValue) {
    hitPoints -= attackValue;
    if (hitPoints <= 0) {
      square.occupant = null;
    }
  }

  @override
  String toString() {
    return runtimeType.toString() + hitPoints.toString() + ': {' + square.toString() + '}\n';
  }

  Being copy(Grid newGrid);
}

class Elf extends Being {
  Elf(Cavern s) : super(s);

  @override
  Type enemy() {
    return Gnome;
  }

  @override
  Being copy(Grid newGrid) {
    return Elf(newGrid.get(square.row, square.col));
  }
}

class Gnome extends Being {
  Gnome(Cavern s) : super(s);

  @override
  Type enemy() {
    return Elf;
  }

  @override
  Being copy(Grid newGrid) {
    return Gnome(newGrid.get(square.row, square.col));
  }
}

void main() {
  Grid grid = Grid();
  List<Being> beings = List();
  String line;
  while ((line = stdin.readLineSync()) != null) {
    List<Square> row = List();
    var chars = line.split('');
    for (int col = 0; col < chars.length; col++) {
      var char = chars[col];
      switch (char) {
        case '#':
          row.add(Rock());
          break;
        case 'G':
        case 'E':
        case '.':
          var cavern = Cavern(grid.nextRowNo(), col, grid);
          row.add(cavern);
          if (char == 'G') {
            beings.add(Gnome(cavern));
          } else if (char == 'E') {
            beings.add(Elf(cavern));
          }
      }
    }
    grid.addRow(row);
  }
  Grid newGrid = grid.copy();
  List<Being> copiedBeings = List.of(beings.map((b) => b.copy(newGrid)));
  part1(copiedBeings);
  part2(grid, beings);
}

void part1(List<Being> beings) {
  beings.forEach((b) => b.square.occupant = b);
  var stillFighting = true;
  var round = 0;
  while (stillFighting) {
    beings.sort((a,b) => a.square < b.square? -1 : 1);
    beings.forEach((b) {
      if (b.hitPoints > 0) {
        var couldMove = b.takeTurn();
        if (!couldMove && !beings.any((c) => c.runtimeType == b.enemy() && c.hitPoints > 0))
          stillFighting = false;
      }
    });
    if (stillFighting) round++;
    beings = beings.where((b) => b.hitPoints > 0).toList();
  }
  var hitPoints = beings.fold(0, (sum, being) => sum + being.hitPoints);
  stdout.writeln(round.toString() + ' * ' + hitPoints.toString() + ' = ' + (round * hitPoints).toString());
}

void part2(Grid origGrid, List<Being> origBeings) {
  int low = 3;
  int step = 1;
  int high = 30000;
  int highScore = -1;
  while (low + 1 < high) {
    int next = min(low + step, high);
    if (next == high) {
      step = 1;
      next = low + 1;
    }
    Grid grid = origGrid.copy();
    List<Being> beings = List.of(origBeings.map((b) => b.copy(grid)));
    beings.forEach((b) => b.attackValue = b.runtimeType == Elf ? next : 3);
    int score = giveMeVictoryOrDeath(beings);
    if (score == -1) {
      low = next;
      step *= 2;
    } else {
      highScore = score;
      high = next;
      step = 1;
    }
  }
  stdout.writeln(high.toString() + ' ' + highScore.toString());
}

int giveMeVictoryOrDeath(List<Being> beings) {
  beings.forEach((b) => b.square.occupant = b);
  var stillFighting = true;
  var round = 0;
  while (stillFighting) {
    beings.sort((a,b) => a.square < b.square? -1 : 1);
    beings.forEach((b) {
      if (b.hitPoints > 0) {
        var couldMove = b.takeTurn();
        if (!couldMove && !beings.any((c) => c.runtimeType == b.enemy() && c.hitPoints > 0))
          stillFighting = false;
      }
    });
    if (stillFighting) round++;
    bool elfDied = false;
    beings = beings.where((b) {
      elfDied |= (b.hitPoints < 0 && b.runtimeType == Elf);
      return b.hitPoints > 0;
    }).toList();
    if (elfDied) return -1;
  }
  var hitPoints = beings.fold(0, (sum, being) => sum + being.hitPoints);
  return round * hitPoints;
}