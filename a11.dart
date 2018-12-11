import 'dart:math';

var serial = 8444;
var cells = new List(300 * 300);

var highValue = -20;
var highX;
var highY;
var highSquare;

cellIndex(int x, int y) {
  var w = x - 1;
  var z = y - 1;
  return w*300 + z;
}

main() {
  for (int x = 300; x > 0; x--) {
    for (int y = 300; y > 0; y--) {
      var rackId = x + 10;
      var powerLevel = rackId * y;
      powerLevel += serial;
      powerLevel *= rackId;
      cells[cellIndex(x,y)] = (powerLevel ~/ 100) % 10 - 5;
      if (x < 299 && y < 299) {
        int value = 0;
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            value += cells[cellIndex(x + i, y + j)];
          }
        }
        if (value > highValue) {
          highValue = value;
          highX = x;
          highY = y;
        }
      }
    }
  }
  print(highX.toString() + "," + highY.toString());

  highValue = -6;
  for (int x = 300; x > 0; x--) {
    for (int y = 300; y > 0; y--) {
      var value = 0;
      var maxSquare = min(301 - x, 301 - y);
      for (int k = 0; k < maxSquare; k++) {
        value += cells[cellIndex(x + k, y + k)];
        for (int i = 0; i < k; i++) {
          value += cells[cellIndex(x + i, y + k)];
          value += cells[cellIndex(x + k, y + i)];
        }
        if (value > highValue) {
          highValue = value;
          highX = x;
          highY = y;
          highSquare = k + 1;
        }
      }
    }
  }
  print(highX.toString() + "," + highY.toString() + "," + highSquare.toString());
}