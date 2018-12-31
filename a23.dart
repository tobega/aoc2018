import 'dart:io';
import 'dart:convert';
import 'dart:math';

const FILE = 'a23.txt';

class Nanobot {
  int x;
  int y;
  int z;
  int range;

  Nanobot(this.x, this.y, this.z, this.range);
}

Future<List<Nanobot>> parseIndata(String path) async {
  var bots = List<Nanobot>();
  Stream lines = new File(path)
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  try {
    var pattern = RegExp(r"pos=<(-?\d+),(-?\d+),(-?\d+)>, r=(\d+)");
    await for (var line in lines) {
      var match = pattern.firstMatch(line);
      bots.add(Nanobot(int.parse(match.group(1)), int.parse(match.group(2)),
          int.parse(match.group(3)), int.parse(match.group(4))));
    }
    return bots;
  } catch (_) {
    ;
  }
}

void main() async {
  var bots = await parseIndata(FILE);
  part1(bots);
  part2(bots);
}

int manhattanDistance(Nanobot a, Nanobot b) {
  return (a.x - b.x).abs() + (a.y - b.y).abs() + (a.z - b.z).abs();
}

void part1(List<Nanobot> bots) {
  var largestRangeBot = bots.reduce((a,b) => a.range > b.range ? a : b);
  bool inRange(Nanobot b) {
    return manhattanDistance(largestRangeBot, b) <= largestRangeBot.range;
  }
  var numInRange = bots.where((b) => inRange(b)).length;
  stdout.writeln(numInRange);
}

// Resolving the planes defining the "cube" gives a nice set of equations
// 0: x + y + z <= r + a + b + c
// 1: x + y - z <= r + a + b - c
// 2: x - y + z <= r + a - b + c
// 3: x - y - z <= r + a - b - c
// 4: - x + y + z <= r - a + b + c
// 5: - x + y - z <= r - a + b - c
// 6: - x - y + z <= r - a - b + c
// 7: - x - y - z <= r - a - b - c
class Cube {
  int intersectingCubes;
  List<int> constraints = new List(8);

  Cube.around(Nanobot bot) {
    intersectingCubes = 1;
    for (int i = 0; i < 8; i++) {
      var abc = [bot.x, bot.y, bot.z];
      var sum = bot.range;
      for (int j = 0; j < 3; j++) {
        if (((i >> j) & 1) == 1) {
          sum -= abc[j];
        } else {
          sum += abc[j];
        }
      }
      constraints[i] = sum;
    }
  }

  Cube.intersect(Cube one, Cube other) {
    intersectingCubes = one.intersectingCubes + other.intersectingCubes;
    for (int i = 0; i < 8; i++) {
      constraints[i] = min(one.constraints[i], other.constraints[i]);
    }
  }

  bool isFeasible() {
    for (int i = 0; i < 4; i++) {
      if (-constraints[i ^ 7] > constraints[i]) return false;
    }
    return true;
  }
}

void part2(List<Nanobot> bots) {
  List<Cube> feasibleCubes = new List();
  var largestIntersect = 0;
  var largest;
  for (var i = 0; i < bots.length; i++) {
    var cube = Cube.around(bots[i]);
    List<Cube> newFeasibleCubes = List();
//    if (bots.length - i > largestIntersect) {
//      newFeasibleCubes.add(cube);
//    }
    if (feasibleCubes.length == 0) {
      newFeasibleCubes.add(cube);
    }
    for (var prev in feasibleCubes) {
      if (prev.intersectingCubes + bots.length - i <= largestIntersect) {
        continue;
      }
//      newFeasibleCubes.add(prev);
      var intersect = Cube.intersect(prev, cube);
      stdout.writeln(' ' + intersect.intersectingCubes.toString() + intersect.constraints.toString());
      if (intersect.isFeasible()) {
        newFeasibleCubes.add(intersect);
        if (intersect.intersectingCubes > largestIntersect) {
          largestIntersect = intersect.intersectingCubes;
          largest = intersect;
        }
      }
    }
    feasibleCubes = newFeasibleCubes;
  }
  stdout.writeln(' ' + largest.intersectingCubes.toString() + largest.constraints.toString());
}