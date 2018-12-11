import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;
import java.util.SortedSet;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.ConcurrentSkipListMap;
import java.util.concurrent.ConcurrentSkipListSet;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

class A10 {
  static final Pattern INPUT_LINE = Pattern.compile("position=<\\s?(-?\\d+),\\s\\s?(-?\\d+)> velocity=<\\s?(-?\\d+),\\s\\s?(-?\\d+)>");

  private final List<PointOfLight> lights;

  A10(List<PointOfLight> lights) {
    this.lights = lights;
  }

  private long calculateScore() {
    Correlator correlator = new Correlator();
    lights.forEach(correlator::append);
    return correlator.getValue();
  }

  // A little magic scoring
  void run() {
    long previousScore = calculateScore();
    boolean isDone = false;
    int i = 0;
    for (; !isDone && i < 100000000; i++) {
      lights.forEach(PointOfLight::move);
      long nextScore = calculateScore();
      //System.out.println("" + nextScore + " " + delta + " " + previousScore + " " + maxDelta);
      isDone = previousScore > 0 && previousScore > nextScore;
      previousScore = nextScore;
    }
    lights.forEach(PointOfLight::backUp);
    printResult();
    System.out.println();
    System.out.println("Iterations " + (i - 1));
  }

  void run2() {
    Plotter plotter = new Plotter();
    lights.forEach(plotter::append);
    int i = 0;
    while (!plotter.isPlottable()) {
      i++;
      lights.forEach(PointOfLight::move);
      plotter = new Plotter();
      lights.forEach(plotter::append);
    }
    plotter.plot();
    System.out.println();
    System.out.println("Iterations " + i);
  }

  private void printResult() {
    Plotter plotter = new Plotter();
    lights.forEach(plotter::append);
    plotter.plot();
  }

  static class PointOfLight {
    private int x;
    private int y;
    private final int dx;
    private final int dy;

    PointOfLight(int x, int y, int dx, int dy) {
      this.x = x;
      this.y = y;
      this.dx = dx;
      this.dy = dy;
    }

    void move() {
      x += dx;
      y += dy;
    }

    void backUp() {
      x -= dx;
      y -= dy;
    }
  }

  static class Correlator {
    ConcurrentMap<Integer, AtomicInteger> rows = new ConcurrentSkipListMap<>();
    ConcurrentMap<Integer, AtomicInteger> columns = new ConcurrentSkipListMap<>();

    void append(PointOfLight p) {
      rows.computeIfAbsent(p.y, k -> new AtomicInteger()).incrementAndGet();
      columns.computeIfAbsent(p.x, k -> new AtomicInteger()).incrementAndGet();
    }

    long getValue() {
      long ssr = rows.values().stream().map(AtomicInteger::get).mapToLong(i -> i * i).sum();
      long ssc = rows.values().stream().map(AtomicInteger::get).mapToLong(i -> i * i).sum();
      return ssr + ssc - rows.size() * rows.size() - columns.size() * columns.size();
    }
  }

  static class Plotter {
    ConcurrentMap<Integer, SortedSet<Integer>> rows = new ConcurrentSkipListMap<>();
    int minX = Integer.MAX_VALUE;
    // for scoring
    int manhattanNeighbours = 0;
    int count = 0;

    void append(PointOfLight p) {
      rows.computeIfAbsent(p.y, k -> new ConcurrentSkipListSet<>()).add(p.x);
      minX = Math.min(minX, p.x);
      count++;
      if (rows.get(p.y).contains(p.x - 1)) {
        manhattanNeighbours += 2;
      }
      if (rows.get(p.y).contains(p.x + 1)) {
        manhattanNeighbours += 2;
      }
      if (rows.containsKey(p.y - 1) && rows.get(p.y - 1).contains(p.x)) {
        manhattanNeighbours += 2;
      }
      if (rows.containsKey(p.y + 1) && rows.get(p.y + 1).contains(p.x)) {
        manhattanNeighbours += 2;
      }
    }

    boolean isPlottable() {
      return (manhattanNeighbours / (double) count) > 1.5;
    }

    void plot() {
      for (SortedSet<Integer> row : rows.values()) {
        int currentX = minX;
        for (int x : row) {
          while (currentX++ < x) {
            System.out.print(' ');
          }
          System.out.print('X');
        }
        System.out.println();
      }
      System.out.println("Final score " + (manhattanNeighbours / (double) count));
    }
  }

  public static void main(String[] args) throws IOException {
    List<PointOfLight> points = Files.readAllLines(Paths.get("a10.txt")).stream().map(l -> {
      Matcher matcher = INPUT_LINE.matcher(l);
      if (!matcher.find()) {
        throw new RuntimeException("Bad line " + l);
      }
      return new PointOfLight(Integer.parseInt(matcher.group(1)), Integer.parseInt(matcher.group(2)), Integer.parseInt(matcher.group(3)), Integer.parseInt(matcher.group(4)));
    }).collect(Collectors.toList());
    new A10(points).run();
  }
}


