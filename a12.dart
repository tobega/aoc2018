import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';

class Game {
  List<int> state;
  Map<int, bool> rules;

  Game(this.state, this.rules);

  void evolve() {
    var newState = List<int>();
    int i = 0;
    int pos = state[0] - 2;
    int locale = 0;

    void checkAndShift() {
      if (rules[locale]) {
        newState.add(pos);
      }
      pos++;
      locale <<= 1;
      locale &= 0x1f;
    }

    while (i < state.length ) {
      if (state[i] == pos + 2) {
        locale |= 1;
        i++;
      }
      checkAndShift();
    }
    while (locale > 0) {
      checkAndShift();
    }
    state = newState;
  }

  int potSum() {
    return state.reduce((a,b) => a+b);
  }
}

const generationsArg = 'generations';

ArgResults argResults;

void main(List<String> arguments) async {
  exitCode = 0; //presume success
  final parser = new ArgParser()
    ..addOption(generationsArg, abbr: 'g', defaultsTo: '20');

  argResults = parser.parse(arguments);
  int generations = int.parse(argResults[generationsArg]);
  List<String> paths = argResults.rest;

  var game = await parseIndata(paths[0]);
  for (int i = 0; i < generations; i++) {
    game.evolve();
  }
  stdout.writeln(game.potSum());
}

Future<Game> parseIndata(String path) async {
  int lineNumber = 1;
  Stream lines = new File(path)
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  try {
    var state;
    var rules = Map<int, bool>();
    await for (var line in lines) {
      if (lineNumber == 1) {
        state = getState(line);
      } else if (lineNumber > 2) {
        Rule rule = getRule(line);
        rules[rule.pattern] = rule.result;
      }
      lineNumber++;
    }
    return Game(state, rules);
  } catch (_) {
    _handleError(path);
  }
}

getState(String line) {
  var state = <int>[];
  var chars = line.replaceFirst('initial state: ', '').split('');
  for (int i = 0; i < chars.length; i++) {
    if (chars[i] == '#') {
      state.add(i);
    }
  }
  return state;
}

class Rule {
  int pattern;
  bool result;

  Rule(this.pattern, this.result);
}

getRule(String line) {
  int pattern = 0;
  line.substring(0, 5).split('').forEach((c) {
    pattern <<= 1;
    if (c == '#') {
      pattern |= 1;
    }
  });
  bool result = line[line.length - 1] == '#';
  return Rule(pattern, result);
}

Future _handleError(String path) async {
  if (await FileSystemEntity.isDirectory(path)) {
    stderr.writeln('error: $path is a directory');
  } else {
    exitCode = 2;
  }
}
