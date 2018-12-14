import 'dart:io';

var input = 635041;

main() {
  part1();
  part2();
}

void part1() {
  var recipes = [3,7];
  var elf = 0;
  var alf = 1;
  while (recipes.length < input + 10) {
    var brew = recipes[elf] + recipes[alf];
    if (brew < 10) {
      recipes.add(brew);
    } else {
      recipes.add(brew ~/ 10);
      recipes.add(brew % 10);
    }
    elf = (elf + recipes[elf] + 1) % recipes.length;
    alf = (alf + recipes[alf] + 1) % recipes.length;
  }
  stdout.writeln(
    recipes.sublist(input, input + 10)
        .map((i) => i.toString())
        .reduce((a,b) => a + b)
  );
}

void part2() {
  var recipes = [3,7];
  var elf = 0;
  var alf = 1;
  var target = input.toString().split('').map((d) => int.parse(d)).toList();
  var targetIndex = 0;
  var recipeIndex = 0;
  while (targetIndex < target.length) {
    var brew = recipes[elf] + recipes[alf];
    if (brew < 10) {
      recipes.add(brew);
    } else {
      recipes.add(brew ~/ 10);
      recipes.add(brew % 10);
    }
    elf = (elf + recipes[elf] + 1) % recipes.length;
    alf = (alf + recipes[alf] + 1) % recipes.length;
    while (recipeIndex < recipes.length && targetIndex < target.length) {
      if (target[targetIndex] == recipes[recipeIndex]) {
        targetIndex++;
      } else {
        // Sloppy, doesn't handle stutters
        targetIndex = target[0] == recipes[recipeIndex] ? 1 : 0;
      }
      recipeIndex++;
    }
  }
  stdout.writeln(recipeIndex - targetIndex);
}