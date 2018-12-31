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

// Resolving the planes defining the octahedron gives a nice set of equations
// 0: x + y + z <= r + a + b + c
// 1: x + y - z <= r + a + b - c
// 2: x - y + z <= r + a - b + c
// 3: x - y - z <= r + a - b - c
// 4: - x + y + z <= r - a + b + c
// 5: - x + y - z <= r - a + b - c
// 6: - x - y + z <= r - a - b + c
// 7: - x - y - z <= r - a - b - c
class Octahedron {
  int intersectingBots;
  List<int> constraints = new List(8);

  Octahedron.empty() {
    intersectingBots = 0;
    constraints = List.generate(8, (i) => 1 << 63 - 1);
  }

  Octahedron.around(Nanobot bot) {
    intersectingBots = 1;
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

  Octahedron.intersect(Octahedron one, Octahedron other) {
    intersectingBots = one.intersectingBots + other.intersectingBots;
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
  bots.sort((a, b) => b.range - a.range); // by decreasing range
  List<Octahedron> cubes = bots.map((n) => Octahedron.around(n)).toList();
  var largestIntersect = Octahedron.empty();
  var feasibleChoices = cubes;
  var remainingFeasibleChoices = List();
  var currentIntersects = List.of([Octahedron.empty()]);
  while (feasibleChoices.isNotEmpty) {
    while (currentIntersects.last.intersectingBots +
        feasibleChoices.length > largestIntersect.intersectingBots) {
      var currentIntersect = Octahedron.intersect(
          currentIntersects.last, feasibleChoices.first);
      currentIntersects.add(currentIntersect);
      if (currentIntersect.intersectingBots >
          largestIntersect.intersectingBots) {
        largestIntersect = currentIntersect;
      }
      remainingFeasibleChoices.add(feasibleChoices.skip(1).toList());
      feasibleChoices = feasibleChoices.skip(1).where((c) =>
          Octahedron.intersect(currentIntersect, c).isFeasible()).toList();
    }
    do {
      currentIntersects.removeLast();
      feasibleChoices = remainingFeasibleChoices.isEmpty ? List() : remainingFeasibleChoices.removeLast();
    } while (feasibleChoices.isEmpty && remainingFeasibleChoices.isNotEmpty);
  }
  // Shaky hypothesis: turning the octahedron equations to >= means that the
  // minimum must be when it is =. But manhattan distance is the sum of absolute
  // values, so it must be the maximum of all the octahedron >= bounds.
  var answer = largestIntersect.constraints.map((i) => -i).reduce((a, b) => max(a,b));
  stdout.writeln(answer);
}