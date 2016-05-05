import std.stdio;
import std.math;
import std.random;
import std.algorithm.comparison;
import std.getopt;
immutable static int SIZE=3;

class Board {
  byte [SIZE][SIZE] board;
  Board parent;  // parent of this board
  int move;    // move that generated this board
  static int heur; // which heuristic we are using to evaluate a board

  this() {parent=null;}

  // prints the board
  void print() {
    writeln(board);
  }

  void print_traceback() {
    if (parent) parent.print_traceback();
    print();
  }

  int solution_length() {
    if (parent) return 1+parent.solution_length();
    else return 0;
  }

  void make_goal() {
    byte num=0;
    // transforms the current state into the goal state
    foreach (i; 0..SIZE)
      foreach (j; 0..SIZE)
        board[i][j]=++num;
  }

  // check whether or not this is a goal board
  bool check_goal() {
    byte num=0;
    foreach (i; 0..SIZE)
      foreach (j; 0..SIZE)
        if (board[i][j]!=++num)
          return false;
    return true;
  }

  private Board clone_board() {
    Board b = new Board;
    foreach (i; 0..SIZE)
      foreach (j; 0..SIZE)
        b.board[i][j]=board[i][j];
    return b;
  }

  Board random_succ() {
    int i = uniform(0,4*SIZE-1);
    return ith_succ(i);
  }

  Board random_walk(int steps) {
    if (steps==0) return this;
    else return random_succ().random_walk(steps-1);
  }

  Board ith_succ(int n) {  // returns the i-th successor of this board

    Board b = clone_board();
    b.parent = this;
    b.move = n;

    if (0<=n && n<SIZE){  // horizontal-left move
      int i=n;
      byte aux=b.board[i][0];
      foreach (int j;0..SIZE-1)
        b.board[i][j]=b.board[i][j+1];
      b.board[i][SIZE-1]=aux;
    }
    else if (SIZE<=n && n<2*SIZE){  // horizontal-right move
      int i=n-SIZE;
      byte aux=b.board[i][SIZE-1];
      foreach_reverse (int j;0..SIZE-1) {
        b.board[i][j+1]=b.board[i][j];
      }
      b.board[i][0]=aux;
    }
    else if (2*SIZE<=n && n<3*SIZE){  // vertical-up move
      int j=n-2*SIZE;
      byte aux=b.board[0][j];
      foreach (int i;0..SIZE-1)
        b.board[i][j]=b.board[i+1][j];
      b.board[SIZE-1][j]=aux;
    }
    else if (3*SIZE<=n && n<4*SIZE){  // vertical-down move
      int j=n-3*SIZE;
      byte aux=b.board[SIZE-1][j];
      foreach_reverse (int i;0..SIZE-1)
        b.board[i+1][j]=b.board[i][j];
      b.board[0][j]=aux;
    }

    return b;
  }

  static void set_heuristic(int h) {
    Board.heur=h;
  }

  int heuristic() {
    if (Board.heur==0) { // null heuristic
      if (check_goal()) return 0;
      else return SIZE;
    }
    else
      return manhattan();
  }

  int manhattan() { // computes sum of Manhattan distances div by SIZE
    int sum=0;
    int mdist(int num, int i, int j) {
      int x=abs((num-1)/SIZE-i);
      int y=abs((num-1)%SIZE-j);

      return min(x,SIZE-x) + min(y,SIZE-y);
    }
    foreach (i;0..SIZE)
      foreach (j;0..SIZE)
        sum += mdist(board[i][j],i,j);
    return sum;
  }

  void succ(Board * B) { // returns an array with all successors of this board
    foreach (int i; 0..4*SIZE)
      B[i]=ith_succ(i);
  }
}

class Stats {
  int problem;
  void describe_me() {
    writeln("#p #size #exp #gen h-id");
  }
  void set_problem(int p) {
    problem=p;
  }
  void record(int s, long e, long g, int h) {
    writeln(problem,"  ", s,"  ",e,"  ",g,"  ",h);
  }
}


Board ida(Board state, Stats st) {
  long expanded;
  long generated;
  int f_bound;
  int new_f_bound;
  immutable int LARGE=10000;
  Board goal_found;


  Board f_dfs(Board state, int g) {
    ++expanded;
    for (int i=0; i<4*SIZE; i++) {
      ++generated;
      Board child=state.ith_succ(i);
      int child_h=child.heuristic();
      if (child_h==0) return child;
      int f_child = SIZE+g+child_h;
      if (f_child<=f_bound) {
        Board goal=f_dfs(child,g+SIZE);
        if (goal) return goal;
      } else {
        if (new_f_bound>f_child)
          new_f_bound=f_child;
      }
    }
    return null;
  }

  expanded=generated=0;
  f_bound = state.heuristic();
  if (f_bound==0) return state;
  while (true) {
    new_f_bound=LARGE;
    goal_found = f_dfs(state,0);
    if (goal_found) break;
    f_bound=new_f_bound;
  }
  int size= goal_found.solution_length();
  st.record(size,expanded,generated,Board.heur);
  return goal_found;
}

int main(string[] args) {
  Board b = new Board();
  Stats st = new Stats();

  b.make_goal();
  //  b.print();

  bool use_manhattan = true;
  bool use_uniform = false;
  bool show_solution = false;
  int problems;

  GetoptResult help_info;

  try {
    help_info = getopt(
                       args,
                       std.getopt.config.required, "problems|p", "Number of random problems to run", &problems,
                       "use_manhattan|m", "Run with the manhattan distance heuristic (hid=1) [default=true]", &use_manhattan,
                       "use_uniform|u", "Run with a uniform heuristic (hid=0) [default=false]",  &use_uniform,
                       "show_solution|s", "Display the problem's solution [default=false]", &show_solution); 
  } catch {
    writeln("Run ",args[0]," -h", " to get a usage example.");
    return 1;
  }
  if (help_info.helpWanted) {
    defaultGetoptPrinter("Options:", help_info.options);
    writeln("Example: ",args[0], " -p 10");
    return 0;
  }

  // set the array with the heuristics to use
  int heuristics[];
  if (use_manhattan) heuristics~=1;
  if (use_uniform) heuristics~=0;

  // describe the stats output
  st.describe_me();

  foreach (prob; 0..problems) {
    Board init = b.random_walk(20); // perform a number of random actions

    st.set_problem(prob);
    init.parent=null;

    // run IDA* using the manhattan heuristic

    foreach (h; heuristics) {
      Board.set_heuristic(h);
      if (show_solution)
        ida(init,st).print_traceback();
      else
        ida(init,st);
    }
  }
  return 0;
}
