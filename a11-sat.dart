import 'dart:math';

var serial = 8444;
var cells = List.filled(301 * 301, 0);

var highValue = -20;
var highX;
var highY;
var highSquare;

cellIndex(int x, int y) {
  return x*300 + y;
}

// Use a Summed-area table
main() {
  for (int x = 1; x <= 300; x++) {
    for (int y = 1; y <= 300; y++) {
      var rackId = x + 10;
      var powerLevel = rackId * y;
      powerLevel += serial;
      powerLevel *= rackId;
      cells[cellIndex(x,y)] = (powerLevel ~/ 100) % 10 - 5
        + cells[cellIndex(x-1,y)] + cells[cellIndex(x,y-1)] - cells[cellIndex(x-1,y-1)];
      if (x > 2 && y > 2) {
        int value = cells[cellIndex(x, y)] + cells[cellIndex(x-3, y-3)]
            - cells[cellIndex(x-3, y)] - cells[cellIndex(x, y-3)];
        if (value > highValue) {
          highValue = value;
          highX = x-2;
          highY = y-2;
        }
      }
    }
  }
  print(highX.toString() + "," + highY.toString());

  highValue = -6;
  for (int x = 1; x <= 300; x++) {
    for (int y = 1; y <= 300; y++) {
      var maxSquare = min(x, y);
      for (int k = 1; k <= maxSquare; k++) {
        int value = cells[cellIndex(x, y)] + cells[cellIndex(x-k, y-k)]
            - cells[cellIndex(x-k, y)] - cells[cellIndex(x, y-k)];
        if (value > highValue) {
          highValue = value;
          highX = x - k + 1;
          highY = y - k + 1;
          highSquare = k;
        }
      }
    }
  }
  print(highX.toString() + "," + highY.toString() + "," + highSquare.toString());
}