import 'dart:io';

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
}

enum Direction {up, left, right, down}

class Target {
  final Being target;
  final int distance;
  final Direction direction;

  Target(this.target, this.distance, this.direction);

  @override
  operator < (Target c) {
    if (c == null) return true;
    return distance < c.distance
      || (distance == c.distance && direction.index < c.direction.index);}

  Target extend(Direction to) {
    return Target(target, distance + 1, to);
  }

  @override
  String toString() {
    return direction.toString() + distance.toString() + '->' + target.runtimeType.toString();
  }
}

abstract class Square {
  mark(Target t);

  remove(Being b);

  add(Being b);

  update(Direction to, Type beingType);

  Target closest(Type enemy);

  Map<Direction, Square> neighbours() {}

  getUpdates(Type beingType) {}

  List<Square> erasePath(Target fromTarget) { return List();}
}

class Rock extends Square {
  @override
  mark(Target t) {}

  @override
  remove(Being b) {}

  @override
  add(Being b) {
    throw Exception();
  }

  @override
  update(Direction to, Type beingType) {}

  @override
  Target closest(Type enemy) {}
}

class Cavern extends Square {
  final int row;
  final int col;
  final Grid grid;

  bool underUpdate = false;
  Map<Type, Target> targets = Map();

  Cavern(this.row, this.col, this.grid);

  @override
  mark(Target t) {
    Target current = targets[t.target.runtimeType];
    if (t < current) {
      targets[t.target.runtimeType] = t;
      if (!isOccupied()) extendPaths(t);
    }
  }

  void extendPaths(Target t) {
    neighbours().forEach((Direction d, Square s) => s.mark(t.extend(reverse(d))));
  }

  @override
  remove(Being b) {
    Target current = targets[b.runtimeType];
    if (current == null) {
      return; // Already removed from other direction
    }
    if (current.target != b) {
      return;
    }
    targets.remove(b.runtimeType);
    var toFix = erasePathFromHere(current);
    toFix.forEach((Square s) => s.getUpdates(b.runtimeType));
    getUpdates(b.runtimeType);
    targets.values.where((t) => t.target.runtimeType != b.runtimeType)
      .forEach((t) => extendPaths(t));
  }

  @override
  add(Being b) {
    Map<Type, List<Square>> toUpdate = erasePaths();
    targets.clear();
    targets[b.runtimeType] = Target(b, 0, Direction.up);
    neighbours().forEach((Direction d, Square s) => s.mark(Target(b, 1, reverse(d))));
    toUpdate.forEach((Type type, List<Square> squares) {
      squares.forEach((Square s) => s.getUpdates(type));
      getUpdates(type);
    });
  }

  Map<Type, List<Square>> erasePaths() {
    Map<Type, List<Square>> toUpdate = Map();
    targets.forEach((Type type, Target target) {
      toUpdate[type] = erasePathFromHere(target);
    });
    return toUpdate;
  }

  List<Square> erasePathFromHere(Target target) {
    return neighbours().values
        .map((s) => s.erasePath(target)).expand((i) => i).toList();
  }

  List<Square> erasePath(Target fromTarget) {
    Target target = targets[fromTarget.target.runtimeType];
    if (target != null && fromTarget.target == target.target && target.distance == fromTarget.distance + 1) {
      targets.remove(fromTarget.target.runtimeType);
      var toUpdate = erasePathFromHere(target);
      toUpdate.add(this);
      return toUpdate;
    }
    return List();
  }

  @override
  update(Direction to, Type beingType) {
    Target current = targets[beingType];
    if (current == null) {
      getUpdates(beingType);
      current = targets[beingType];
    }
    if (current != null && (!isOccupied() || current.distance == 0)) {
      neighbours()[to].mark(current.extend(reverse(to)));
    }
  }

  @override
  getUpdates(Type beingType) {
    if (underUpdate) return;
    underUpdate = true;
    neighbours().forEach((Direction d, Square s) => s.update(reverse(d), beingType));
    underUpdate = false;
  }

  @override
  Target closest(Type enemy) {
    return targets[enemy];
  }

  @override
  Map<Direction, Square> neighbours() {
    return {
      Direction.up: grid.get(row - 1, col),
      Direction.left: grid.get(row, col - 1),
      Direction.right: grid.get(row, col + 1),
      Direction.down: grid.get(row + 1, col)};
  }

  @override
  operator < (Cavern c) {
    return row < c.row || (row == c.row && col < c.col);
  }

  Direction reverse(Direction d) {
    switch (d) {
      case Direction.up: return Direction.down;
      case Direction.down: return Direction.up;
      case Direction.left: return Direction.right;
      case Direction.right: return Direction.left;
    }
  }

  @override
  String toString() {
    return runtimeType.toString() + '(' + row.toString() + ', ' + col.toString() + '): {' + targets.toString() + '}';
  }

  bool isOccupied() {
    return targets.values.any((t) => t.distance == 0);
  }
}

abstract class Being {
  Cavern square;
  int hitPoints = 200;
  final int attackValue = 3;

  Being(this.square);

  Type enemy();

  bool takeTurn() {
    Target closest = square.closest(enemy());
    if (closest == null) {
      return false; // Game is won
    }
    if (closest.distance > 1) {
      square.remove(this);
      square = square.neighbours()[closest.direction];
      square.add(this);
      closest = square.closest(enemy());
    }
    if (closest.distance == 1) {
      square.neighbours().values.map((Square s) => s.closest(enemy()))
          .where((Target t) => t != null && t.distance == 0)
          .map((t) => t.target)
          .reduce((a, b) => b.hitPoints < a.hitPoints ? b : a)
      .hit(attackValue);
    }
    return true;
  }

  void hit(int attackValue) {
    hitPoints -= attackValue;
    if (hitPoints <= 0) {
      square.remove(this);
    }
  }

  putOnMap() {
    square.add(this);
  }

  @override
  String toString() {
    return runtimeType.toString() + ': {' + square.toString() + '}\n';
  }
}

class Elf extends Being {
  Elf(Cavern s) : super(s);

  @override
  Type enemy() {
    return Gnome;
  }
}

class Gnome extends Being {
  Gnome(Cavern s) : super(s);

  @override
  Type enemy() {
    return Elf;
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
  beings.forEach((b) => b.putOnMap());
  part1(beings);
}

void part1(List<Being> beings) {
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