class A9 {
  private final int players;
  private final long[] scores;
  private final int marbles;
  private final Circle circle;

  private class Circle {
    private int[] circle;
    private int head;
    private int tail;

    Circle(int size) {
      circle = new int[size];
      head = 0;
      tail = 0;
      circle[0] = 0;
    }

    void rollOne() {
      head = forward(head);
      circle[head] = circle[tail];
      tail = forward(tail);
    }

    private int forward(int m) {
      return (m + 1) % circle.length;
    }

    void put(int marble) {
      head = forward(head);
      circle[head] = marble;
    }

    void rollBack7() {
      for (int i=0; i<7; i++) {
        tail = back(tail);
        circle[tail] = circle[head];
        head = back(head);
      }
    }

    private int back(int m) {
       m = (m - 1) % circle.length;
       if (m < 0) m += circle.length;
       return m;
    }

    int take() {
      int v = circle[head];
      head = back(head);
      return v;
    }
  }

  A9(int players, int marbles) {
    this.players = players;
    scores = new long[players];
    this.marbles = marbles;
    this.circle = new Circle(marbles);
  }

  void play() {
    for (int i = 1; i <= marbles; i++) {
      if (i % 23 == 0) {
        circle.rollBack7();
        scores[i % players] += i + circle.take();
        circle.rollOne();
      } else {
        circle.rollOne();
        circle.put(i);
      }
    }
  }

  long getMaxScore() {
    long max = 0;
    for (int i = 0; i<players; i++) {
      if (scores[i] > max) max = scores[i];
    }
    return max;
  }

  public static void main(String[] args) throws Exception {
    int players = Integer.parseInt(args[0]);
    int marbles = Integer.parseInt(args[1]);
    A9 game = new A9(players, marbles);
    game.play();
    System.out.println(game.getMaxScore());
  }
}

