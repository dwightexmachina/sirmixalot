/// Bundled MIXAL programs from (or in the spirit of) TAOCP.
class GalleryProgram {
  final String id;
  final String section;
  final String title;
  final String description;
  final String source;

  /// For array-oriented programs (e.g. sorts), the memory region to draw as a
  /// bar chart: first address and element count. Null hides the chart.
  final int? arrayBase;
  final int? arrayLength;

  const GalleryProgram({
    required this.id,
    required this.section,
    required this.title,
    required this.description,
    required this.source,
    this.arrayBase,
    this.arrayLength,
  });

  String get label => '§$section · $title';

  /// The TAOCP volume this program comes from. The leading section number is
  /// the *chapter*, and each volume spans two chapters: Vol 1 = ch. 1–2,
  /// Vol 2 = ch. 3–4, Vol 3 = ch. 5–6, Vol 4 = ch. 7+.
  int get volume {
    final chapter = int.parse(section.split('.').first);
    if (chapter <= 2) return 1;
    if (chapter <= 4) return 2;
    if (chapter <= 6) return 3;
    return 4;
  }
}

/// TAOCP volume titles, for grouping the gallery by book.
const Map<int, String> bookTitles = {
  1: 'Fundamental Algorithms',
  2: 'Seminumerical Algorithms',
  3: 'Sorting and Searching',
  4: 'Combinatorial Algorithms',
};

/// Compares dotted section numbers component-by-component (1.1 < 1.3.2 < 1.4.1).
int _compareSections(String a, String b) {
  final pa = a.split('.').map(int.parse).toList();
  final pb = b.split('.').map(int.parse).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    if (pa[i] != pb[i]) return pa[i] - pb[i];
  }
  return pa.length - pb.length;
}

/// The gallery programs, ordered by volume and then by section number.
List<GalleryProgram> get gallery => [..._galleryPrograms]..sort((a, b) =>
    a.volume != b.volume
        ? a.volume - b.volume
        : _compareSections(a.section, b.section));

const List<GalleryProgram> _galleryPrograms = [
  GalleryProgram(
    id: 'program-m',
    section: '1.3.2',
    title: 'Program M — Find the Maximum',
    description:
        'Scans X[1..10] from the right, keeping the running maximum in rA '
        'and its index in rI2. Watch CMPA/JGE decide whether CHANGEM runs.',
    source: '''
* TAOCP 1.3.2, Program M: maximum of X[1..N].
* Result: max in rA, its index in rI2.
X       EQU  1000
N       EQU  10
        ORIG X+1
        CON  231
        CON  88
        CON  512
        CON  64
        CON  999
        CON  305
        CON  907
        CON  118
        CON  730
        CON  190
        ORIG 3000
MAXIMUM STJ  EXIT
INIT    ENT3 0,1
        JMP  CHANGEM
LOOP    CMPA X,3
        JGE  *+3
CHANGEM ENT2 0,3
        LDA  X,3
        DEC3 1
        J3P  LOOP
EXIT    JMP  *
START   ENT1 N
        JMP  MAXIMUM
        HLT
        END  START
''',
  ),
  GalleryProgram(
    id: 'euclid',
    section: '1.1',
    title: 'Algorithm E — Euclid’s GCD',
    description:
        'gcd(1071, 462) by repeated division: the SRAX 5 idiom widens rA '
        'into rA:rX for DIV. The answer (21) ends in rA.',
    source: '''
* Euclid's algorithm: gcd(U, V) left in rA.
        ORIG 1000
U       CON  1071
V       CON  462
W       CON  0
        ORIG 3000
START   LDA  U
        LDX  V
2H      JXZ  1F
        STX  W
        SRAX 5
        DIV  W
        LDA  W
        JMP  2B
1H      HLT
        END  START
''',
  ),
  GalleryProgram(
    id: 'hello-printer',
    section: '1.3.1',
    title: 'OUT — Line Printer Demo',
    description:
        'Prints one 24-word line on unit 18 using ALF character constants. '
        'The smallest possible I/O program.',
    source: '''
* Print one line on the line printer (unit 18).
        ORIG 3000
START   OUT  MSG(18)
        HLT
MSG     ALF  "HELLO"
        ALF  ", MIX"
        END  START
''',
  ),
  GalleryProgram(
    id: 'char-demo',
    section: '1.3.1',
    title: 'NUM & CHAR — Number Formatting',
    description:
        'Computes 60 * 24 * 7 = minutes per week, converts it to character '
        'code with CHAR, and prints it right-justified.',
    source: '''
* Compute minutes per week and print it.
BUF     EQU  2000
        ORIG 3000
START   ENTA 60
        MUL  =24=
        SLAX 5
        MUL  =7=
        SLAX 5
        CHAR
        STA  BUF
        STX  BUF+1
        OUT  BUF(18)
        HLT
        END  START
''',
  ),
  GalleryProgram(
    id: 'primes',
    section: '1.3.2',
    title: 'Program P — The First 500 Primes',
    description:
        'The classic. Sieves the first 500 primes by trial division into '
        'PRIME[1..500] (the 500th is 3571), then prints them ten to a line. '
        'Reconstructed faithfully — verified to produce the right table, '
        'though not byte-identical to Knuth’s buffered listing.',
    source: '''
* TAOCP 1.3.2, Program P — the first 500 primes (reconstruction).
* Trial division into PRIME[1..500], then a printed table of 50 lines.
PRIME   EQU  2000
N       EQU  500
BUF     EQU  2600
        ORIG 3000
START   ENTA 2
        STA  PRIME+1      is  PRIME[1] = 2
        ENT1 1            is  rI1 = count of primes found
        ENTA 1
        STA  CAND         is  candidate = 1
* ---- find the primes ----
NEXTC   LDA  CAND
        INCA 2
        STA  CAND         is  test only odd candidates 3,5,7,...
        ENT3 1            is  rI3 = divisor index j
TESTJ   INC3 1
        ENTA 0,3
        DECA 0,1
        JAP  ISPRIM       is  j > count  =>  prime
        LDA  PRIME,3
        MUL  PRIME,3      is  rX = PRIME[j]^2
        STX  PSQ
        LDA  CAND
        CMPA PSQ
        JL   ISPRIM       is  candidate < PRIME[j]^2  =>  prime
        ENTA 0
        LDX  CAND
        DIV  PRIME,3      is  rX = candidate mod PRIME[j]
        JXZ  NEXTC        is  divisible  =>  composite
        JMP  TESTJ
ISPRIM  INC1 1
        LDA  CAND
        STA  PRIME,1      is  PRIME[count] = candidate
        ENTA 0,1
        DECA N
        JAN  NEXTC        is  fewer than 500  =>  keep sieving
* ---- print the table, ten primes to a line ----
PRINT   ENT1 0            is  rI1 = prime index
PLINE   ENT2 0            is  rI2 = column counter
        ENT4 0            is  rI4 = buffer word offset
PCOL    INC1 1
        LDA  PRIME,1
        CHAR
        STX  BUF,4
        INC4 2            is  leave a blank word between columns
        INC2 1
        ENTA 0,2
        DECA 10
        JAN  PCOL
        OUT  BUF(18)
        ENTA 0,1
        DECA N
        JAN  PLINE
        HLT
CAND    CON  0
PSQ     CON  0
        END  START
''',
  ),
  GalleryProgram(
    id: 'perm-inverse',
    section: '1.3.3',
    title: 'Algorithm I — Invert a Permutation in Place',
    description:
        'Replaces the permutation X[1..n] with its inverse using no extra '
        'array — it walks each cycle, rewriting links and marking touched '
        'entries with a negative sign, then flips the signs back. Here '
        'X = (2 3 1)(5 6 4) becomes its inverse [3 1 2 6 4 5].',
    source: '''
* TAOCP 1.3.3 — invert the permutation X[1..N] in place (sign-marked cycles).
X       EQU  1000
N       EQU  6
        ORIG 3000
START   ENT1 1            is  rI1 = m, the cycle start
OUTER   LDA  X,1
        JAN  SKIP         is  X[m] < 0  =>  cycle already done
        ENT3 0,1          is  prev = m
        LD2  X,1          is  cur  = X[m]
1H      ENTA 0,2
        DECA 0,1
        JAZ  2F           is  cur = m  =>  close the cycle
        LD4  X,2          is  next = X[cur]
        ENNA 0,3
        STA  X,2          is  X[cur] = -prev
        ENT3 0,2          is  prev = cur
        ENT2 0,4          is  cur  = next
        JMP  1B
2H      ENNA 0,3
        STA  X,1          is  X[m] = -prev
SKIP    INC1 1
        CMP1 =N=
        JLE  OUTER
* ---- flip every sign back to positive ----
        ENT1 1
3H      LDAN X,1
        STA  X,1
        INC1 1
        CMP1 =N=
        JLE  3B
        HLT
        ORIG X+1
        CON  2
        CON  3
        CON  1
        CON  5
        CON  6
        CON  4
        END  START
''',
  ),
  GalleryProgram(
    id: 'perm-product',
    section: '1.3.3',
    title: 'Multiply Two Permutations',
    description:
        'Forms the product Z = A∘B of two permutations given in array form, '
        'where Z[i] = A[B[i]] — the core operation behind §1.3.3’s '
        'permutation multiplication (Knuth’s Program A additionally parses '
        'cycle notation, omitted here for clarity).',
    source: '''
* TAOCP 1.3.3 — product of permutations A and B (array form): Z[i] = A[B[i]].
A       EQU  1000
B       EQU  1010
Z       EQU  1020
N       EQU  6
        ORIG 3000
START   ENT1 1
LOOP    LD2  B,1          is  k = B[i]
        LDA  A,2          is  A[k]
        STA  Z,1          is  Z[i] = A[B[i]]
        INC1 1
        CMP1 =N=
        JLE  LOOP
        HLT
        ORIG A+1
        CON  2
        CON  3
        CON  1
        CON  5
        CON  6
        CON  4
        ORIG B+1
        CON  6
        CON  5
        CON  4
        CON  3
        CON  2
        CON  1
        END  START
''',
  ),
  GalleryProgram(
    id: 'max-subroutine',
    section: '1.4.1',
    title: 'Maximum as a Subroutine',
    description:
        'Program M repackaged as a callable subroutine, showing the MIX '
        'calling convention: the caller sets rI3 = n and JMPs in; MAXN saves '
        'its return with STJ, finds the maximum (999 at index 5), and JMPs '
        'back through the patched exit.',
    source: '''
* TAOCP 1.4.1 — the maximum-finder as a subroutine.
* Entry: rI3 = n.  Exit: rA = max of X[1..n], rI2 = its index.
X       EQU  1000
        ORIG 3000
MAXN    STJ  EXITM        is  save the return address
        ENT2 0,3
        LDA  X,3
        DEC3 1
        J3Z  EXITM        is  n = 1  =>  done
LOOP    CMPA X,3
        JGE  *+3
        ENT2 0,3
        LDA  X,3
        DEC3 1
        J3P  LOOP
EXITM   JMP  *            is  return (address patched by STJ)
* ---- caller ----
START   ENT3 10
        JMP  MAXN
        STA  ANS          is  ANS  = maximum
        ST2  ANSI         is  ANSI = its index
        HLT
ANS     CON  0
ANSI    CON  0
        ORIG X+1
        CON  231
        CON  88
        CON  512
        CON  64
        CON  999
        CON  305
        CON  907
        CON  118
        CON  730
        CON  190
        END  START
''',
  ),
  GalleryProgram(
    id: 'coroutine',
    section: '1.4.2',
    title: 'Coroutines — Producer & Consumer',
    description:
        'Two coroutines that hand control back and forth: A produces the '
        'numbers 1–5 (then a 0 sentinel), B sums them. Each keeps its resume '
        'address in a cell (ARES/BRES) and jumps to the other via an indexed '
        'JMP — the MIX coroutine linkage. The sum, 15, ends in SUM (1001).',
    source: '''
* Two symmetric coroutines sharing control (spirit of TAOCP 1.4.2).
* A produces 1..5 then a 0 sentinel; B sums them. Result 15 in SUM.
ITEM    EQU  1000
SUM     EQU  1001
        ORIG 3000
START   ENTA BSTART
        STA  BRES         is  BRES = where B first starts
        JMP  ASTART
* ---- coroutine A: producer ----
ASTART  ENT1 0
A1      INC1 1
        ST1  ITEM         is  hand the next value to B
        ENTA A2
        STA  ARES         is  remember where to resume A
        LD5  BRES
        JMP  0,5          is  resume B
A2      ENTA 0,1
        DECA 5
        JAN  A1           is  produced fewer than 5  =>  keep going
        ENTA 0
        STA  ITEM         is  0 sentinel: no more values
        ENTA A3
        STA  ARES
        LD5  BRES
        JMP  0,5
A3      HLT
* ---- coroutine B: consumer ----
BSTART  ENTA 0
        STA  SUM
B1      LDA  ITEM
        JAZ  BDONE        is  sentinel  =>  finished
        ADD  SUM
        STA  SUM          is  SUM += ITEM
        ENTA B2
        STA  BRES         is  remember where to resume B
        LD5  ARES
        JMP  0,5          is  resume A
B2      JMP  B1
BDONE   HLT
ARES    CON  0
BRES    CON  0
        END  START
''',
  ),
  GalleryProgram(
    id: 'lcg',
    section: '3.2.1',
    title: 'Linear Congruential Generator',
    description:
        'The workhorse pseudo-random generator: X ← (aX + c) mod m, with '
        'm = 64⁵ (the word size). MUL leaves the low word (a·X mod m) in rX '
        'for free, and ADD wraps mod m automatically. Writes eight values '
        'starting at 1000.',
    source: '''
* Linear congruential generator (TAOCP 3.2.1): X = (aX + c) mod m, m = 64^5.
RAND    EQU  1000
N       EQU  8
        ORIG 3000
START   ENT1 0
LOOP    LDA  SEED
        MUL  MULT          is  rX = (a*X) mod m  (low half of the product)
        STX  SEED
        LDA  SEED
        ADD  INCR          is  + c, wrapping mod m
        STA  SEED
        STA  RAND,1        is  save this value
        INC1 1
        CMP1 =N=
        JL   LOOP
        HLT
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
        END  START
''',
  ),
  GalleryProgram(
    id: 'random-range',
    section: '3.4.2',
    title: 'Random Integers in a Range — Dice',
    description:
        'Turns the raw generator into dice rolls in 1–6 using the range '
        'technique: for a fraction U = X/m, the value ⌊kU⌋ is exactly the '
        'high word of k·X — so MUL by 6 and read rA. Writes ten rolls '
        'starting at 1000.',
    source: '''
* Random integers in a range (TAOCP 3.4.2): roll ten dice in 1..6.
* floor(k * X / m) is just the HIGH word of k*X, left in rA by MUL.
ROLLS   EQU  1000
N       EQU  10
        ORIG 3000
START   ENT1 0
LOOP    LDA  SEED
        MUL  MULT          is  advance the generator...
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED          is  ...SEED now holds the next value
        MUL  SIX           is  rA = floor(6 * SEED / m)  (0..5)
        INCA 1             is  shift to 1..6
        STA  ROLLS,1
        INC1 1
        CMP1 =N=
        JL   LOOP
        HLT
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
SIX     CON  6
        END  START
''',
  ),
  GalleryProgram(
    id: 'shuffle',
    section: '3.4.2',
    title: 'Random Permutation — Shuffle',
    description:
        'Algorithm P: shuffle A[1..8] into a uniformly random order. For j '
        'from 8 down to 2 it draws a random k in 1..j (the range trick) and '
        'swaps A[j] with A[k]. The shuffled array ends at 1001.',
    source: '''
* Random permutation, Algorithm P (TAOCP 3.4.2): shuffle A[1..N] in place.
A       EQU  1000
N       EQU  8
        ORIG 3000
START   ENT2 N             is  j = N, working downward
JLOOP   ST2  JJ
        LDA  SEED
        MUL  MULT          is  advance the generator...
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  JJ            is  rA = floor(j * X / m) in 0..j-1
        INCA 1             is  k in 1..j
        STA  KK
        LD3  KK
        LDA  A,2           is  swap A[j] and A[k]
        STA  TMP
        LDA  A,3
        STA  A,2
        LDA  TMP
        STA  A,3
        DEC2 1
        ENTA 0,2
        DECA 1
        JAP  JLOOP         is  j >= 2  =>  keep shuffling
        HLT
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
JJ      CON  0
KK      CON  0
TMP     CON  0
        ORIG A+1
        CON  1
        CON  2
        CON  3
        CON  4
        CON  5
        CON  6
        CON  7
        CON  8
        END  START
''',
  ),
  GalleryProgram(
    id: 'mp-add',
    section: '4.3.1',
    title: 'Multiple-Precision Addition',
    description:
        'Adds two four-word big integers (radix 64⁵) digit by digit from the '
        'least-significant end, using ADD’s overflow toggle as the carry. '
        'Here (64²⁰ − 1) + 1 rolls over to all zeros with a carry out. The '
        'sum is at 1020; the final carry is in CARRY.',
    source: '''
* Multiple-precision addition (TAOCP 4.3.1): W = U + V, N words, radix 64^5.
* The carry between words is exactly ADD's overflow toggle.
U       EQU  1000
V       EQU  1010
W       EQU  1020
N       EQU  4
        ORIG 3000
START   ENTA 0
        STA  CARRY
        ENT1 N-1           is  start at the least-significant word
LOOP    LDA  U,1
        ADD  V,1           is  u + v (may carry)
        ENT3 0
        JNOV *+2
        ENT3 1             is  carry out of this add
        ADD  CARRY         is  add the incoming carry
        JNOV *+2
        ENT3 1
        STA  W,1
        ST3  CARRY         is  carry into the next word
        DEC1 1
        J1NN LOOP
        HLT
CARRY   CON  0
        ORIG U
        CON  1073741823
        CON  1073741823
        CON  1073741823
        CON  1073741823
        ORIG V
        CON  0
        CON  0
        CON  0
        CON  1
        END  START
''',
  ),
  GalleryProgram(
    id: 'binary-gcd',
    section: '4.5.2',
    title: 'Binary GCD — Algorithm B',
    description:
        'Euclid without division: strip common factors of 2, then repeatedly '
        'halve the even number and subtract the smaller from the larger. '
        'gcd(1071, 462) = 21, left in RESULT — computed with only halving, '
        'comparison, and subtraction.',
    source: '''
* Binary GCD, Algorithm B (TAOCP 4.5.2).  gcd(U, V) -> RESULT.
        ORIG 3000
START   LDA  U
        STA  UU
        LDA  V
        STA  VV
        ENT4 0             is  k = count of common factors of 2
COMMON  ENTA 0
        LDX  UU
        DIV  TWO
        JXNZ AFTER         is  U odd  =>  no more common 2s
        ENTA 0
        LDX  VV
        DIV  TWO
        JXNZ AFTER         is  V odd  =>  no more common 2s
        ENTA 0
        LDX  UU
        DIV  TWO
        STA  UU            is  both even: halve both, k++
        ENTA 0
        LDX  VV
        DIV  TWO
        STA  VV
        INC4 1
        JMP  COMMON
AFTER   ENTA 0
        LDX  UU
        DIV  TWO
        JXNZ MAIN          is  make U odd
        STA  UU
        JMP  AFTER
MAIN    ENTA 0
        LDX  VV
        DIV  TWO
        JXNZ CMPUV         is  make V odd
        STA  VV
        JMP  MAIN
CMPUV   LDA  UU
        CMPA VV
        JLE  NOSWAP
        LDA  UU
        STA  T
        LDA  VV
        STA  UU
        LDA  T
        STA  VV
NOSWAP  LDA  VV
        SUB  UU
        STA  VV            is  V = V - U (now even)
        JAZ  FIN           is  V == 0  =>  U is the gcd
        JMP  MAIN
FIN     LDA  UU
        STA  RES
        ENT1 0,4
DBL     J1Z  STORE
        LDA  RES
        ADD  RES           is  RES *= 2, k times  (restore common 2s)
        STA  RES
        DEC1 1
        JMP  DBL
STORE   LDA  RES
        STA  RESULT
        HLT
U       CON  1071
V       CON  462
UU      CON  0
VV      CON  0
T       CON  0
RES     CON  0
RESULT  CON  0
TWO     CON  2
        END  START
''',
  ),
  GalleryProgram(
    id: 'power',
    section: '4.6.3',
    title: 'Evaluation of Powers — Squaring',
    description:
        'Computes bⁿ by right-to-left binary exponentiation: scan the '
        'exponent’s bits (via divide-by-2), squaring the base each step and '
        'multiplying it into the result when the bit is 1. 3¹³ = 1,594,323, '
        'left in RESULT — far fewer multiplies than the naïve n−1.',
    source: '''
* Evaluation of powers (TAOCP 4.6.3): b^n by right-to-left binary method.
        ORIG 3000
START   ENTA 1
        STA  RESULT
        LDA  BASE0
        STA  BASE
        LDA  EXP
        STA  E
LOOP    LDA  E
        JAZ  DONE
        ENTA 0
        LDX  E
        DIV  TWO           is  rA = e/2, rX = low bit of e
        STA  E
        JXZ  SKIP          is  bit 0  =>  don't multiply
        LDA  RESULT
        MUL  BASE
        STX  RESULT        is  result *= base
SKIP    LDA  BASE
        MUL  BASE
        STX  BASE          is  base *= base
        JMP  LOOP
DONE    HLT
RESULT  CON  0
BASE    CON  0
E       CON  0
BASE0   CON  3
EXP     CON  13
TWO     CON  2
        END  START
''',
  ),
  GalleryProgram(
    id: 'insertion-sort',
    section: '5.2.1',
    title: 'Straight Insertion Sort',
    description:
        'Algorithm S: grow a sorted prefix by sliding each element left past '
        'everything larger. Fills its own 100 random values, then sorts. '
        'O(n²) — about 35,000u here: better than bubble, but the shifting '
        'work grows quadratically. Watch the sorted region spread from the '
        'left.',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Straight insertion sort (TAOCP 5.2.1, Algorithm S). Sorts A[1..N].
A       EQU  1000
N       EQU  100
        ORIG 3000
START   ENT1 1
FILL    LDA  SEED
        MUL  MULT
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  C256          is  random height 0..255
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  FILL
        ENT2 2             is  j = 2
JLOOP   LDA  A,2
        STA  KEY           is  key = A[j]
        ENT1 -1,2          is  i = j - 1
ILOOP   ENTA 0,1
        JANP INS           is  i < 1  =>  insert
        LDA  A,1
        CMPA KEY
        JLE  INS           is  A[i] <= key  =>  insert
        LDA  A,1
        STA  A+1,1         is  slide A[i] up to A[i+1]
        DEC1 1
        JMP  ILOOP
INS     LDA  KEY
        STA  A+1,1         is  drop key into the gap
        INC2 1
        CMP2 =N=
        JLE  JLOOP
        HLT
KEY     CON  0
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
C256    CON  256
        END  START
''',
  ),
  GalleryProgram(
    id: 'bubble-sort',
    section: '5.2.2',
    title: 'Bubble Sort',
    description:
        'The classic exchange sort: sweep the array swapping out-of-order '
        'neighbors, floating the largest remaining value to the end each '
        'pass. Fills its own 100 random values, then sorts. The slowest here '
        'by far (~76,000u — about 3× Shellsort): pure O(n²) with a swap-heavy '
        'inner loop. Watch the big bars march right, one pass at a time.',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Bubble sort (TAOCP 5.2.2). Sorts A[1..N] by exchanging neighbors.
A       EQU  1000
N       EQU  100
        ORIG 3000
START   ENT1 1
FILL    LDA  SEED
        MUL  MULT
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  C256          is  random height 0..255
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  FILL
        ENT2 N
        DEC2 1             is  i = N-1 passes, shrinking
OUTER   ENTA 0,2
        JANP DONE          is  i < 1  =>  sorted
        ENT1 1             is  j = 1
INNER   LDA  A,1
        CMPA A+1,1
        JLE  NOSWAP        is  in order, leave it
        LDA  A,1
        STA  T
        LDA  A+1,1
        STA  A,1
        LDA  T
        STA  A+1,1         is  swap A[j], A[j+1]
NOSWAP  INC1 1
        ENTA 0,1
        DECA 0,2
        JANP INNER         is  j <= i  =>  keep sweeping
        DEC2 1
        JMP  OUTER
DONE    HLT
T       CON  0
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
C256    CON  256
        END  START
''',
  ),
  GalleryProgram(
    id: 'shellsort',
    section: '5.2.1',
    title: 'Shellsort',
    description:
        'Insertion sort with shrinking gaps (N/2, N/4, …, 1). Early passes '
        'move elements long distances so the array is nearly sorted by the '
        'time the gap reaches 1. Fills its own 100 random values, then sorts '
        '— the fastest of the four here (~25,000u, a third of bubble). Watch '
        'the long-range hops early, then fine cleanup at gap 1.',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Shellsort (TAOCP 5.2.1): diminishing-increment insertion sort.
A       EQU  1000
N       EQU  100
        ORIG 3000
START   ENT1 1
FILL    LDA  SEED
        MUL  MULT
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  C256          is  random height 0..255
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  FILL
        ENTA 0
        LDX  =N=
        DIV  TWO
        STA  HH            is  gap h = N/2
HLOOP   LDA  HH
        JAZ  DONE          is  h = 0  =>  sorted
        LD1  HH
        INC1 1             is  i = h+1
ILOOP   ENTA 0,1
        DECA N
        JAP  HNEXT         is  i > N  =>  next gap
        LDA  A,1
        STA  KEY
        ENT2 0,1           is  j = i
JLOOP   ENTA 0,2
        SUB  HH
        JANP INS           is  j <= h  =>  insert
        STA  JMH
        LD3  JMH           is  index j-h
        LDA  A,3
        CMPA KEY
        JLE  INS
        LDA  A,3
        STA  A,2           is  A[j] = A[j-h]
        ENT2 0,3           is  j = j-h
        JMP  JLOOP
INS     LDA  KEY
        STA  A,2
        INC1 1
        JMP  ILOOP
HNEXT   ENTA 0
        LDX  HH
        DIV  TWO
        STA  HH            is  halve the gap
        JMP  HLOOP
DONE    HLT
HH      CON  0
KEY     CON  0
JMH     CON  0
TWO     CON  2
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
C256    CON  256
        END  START
''',
  ),
  GalleryProgram(
    id: 'heapsort',
    section: '5.2.3',
    title: 'Heapsort — Algorithm H',
    description:
        'Builds a max-heap in the array, then repeatedly swaps the root '
        '(largest) to the end and sifts the new root down; the sorted tail '
        'grows from the right. Fills its own 100 random values, then sorts. '
        'Guaranteed O(n log n) (~31,000u here — comfortably beats bubble’s '
        '76,000u). Uses a SIFT subroutine via STJ linkage.',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Heapsort, Algorithm H (TAOCP 5.2.3): build a max-heap, then extract.
A       EQU  1000
N       EQU  100
        ORIG 3000
START   ENT1 1
FILL    LDA  SEED
        MUL  MULT
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  C256          is  random height 0..255
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  FILL
        ENTA N
        STA  HEND          is  heap size = N while building
        ENTA 0
        LDX  =N=
        DIV  TWO
        STA  SS            is  start sifting from N/2
BUILD   LDA  SS
        JANP PHASE2
        LD1  SS
        JMP  SIFT
        LDA  SS
        DECA 1
        STA  SS
        JMP  BUILD
PHASE2  ENT4 N             is  end = N, shrinking
SLOOP2  ENTA 0,4
        DECA 1
        JANP HLTX          is  end <= 1  =>  done
        LDA  A+1
        STA  TSWAP
        LDA  A,4
        STA  A+1
        LDA  TSWAP
        STA  A,4           is  move the max (root) to A[end]
        ENTA 0,4
        DECA 1
        STA  HEND          is  shrink the heap
        ENT1 1
        JMP  SIFT          is  restore the heap from the root
        DEC4 1
        JMP  SLOOP2
HLTX    HLT
* --- SIFT: sift A[rI1] down within A[1..HEND] ---
SIFT    STJ  SEXIT
SLOOP   ENTA 0,1
        STA  TI
        ADD  TI
        STA  TC            is  child = 2*i
        LD2  TC
        LDA  TC
        CMPA HEND
        JG   SEXIT         is  no children
        LDA  TC
        INCA 1
        CMPA HEND
        JG   NOCH1         is  only a left child
        LDA  A+1,2
        CMPA A,2
        JLE  NOCH1
        INC2 1             is  pick the larger child
NOCH1   LDA  A,1
        CMPA A,2
        JGE  SEXIT         is  parent already >= child
        LDA  A,1
        STA  TSWAP
        LDA  A,2
        STA  A,1
        LDA  TSWAP
        STA  A,2           is  swap parent and child
        ENT1 0,2
        JMP  SLOOP
SEXIT   JMP  *
HEND    CON  0
SS      CON  0
TI      CON  0
TC      CON  0
TSWAP   CON  0
TWO     CON  2
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
C256    CON  256
        END  START
''',
  ),
  GalleryProgram(
    id: 'list-insertion',
    section: '5.2.1',
    title: 'List Insertion Sort',
    description:
        'Program L: insert each element into a sorted linked list by adjusting '
        'links only — no data is moved during sorting. At the end it walks the '
        'list to materialize the order into the array. O(n²) comparisons '
        '(~61,000u here). Bars jump only during the final materialize.',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* List insertion sort, Program L (TAOCP 5.2.1): sort via a link array,
* then walk the list to materialize the sorted order.
A       EQU  1000
LINK    EQU  1300
B       EQU  1500
N       EQU  100
        ORIG 3000
START   ENT1 1
FILL    LDA  SEED
        MUL  MULT
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  C256
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  FILL
        ENTA 0
        STA  HEAD
        ENT1 1
LINS    LDA  HEAD
        STA  P
        ENTA 0
        STA  PREV
LFIND   LDA  P
        JAZ  LINSRT
        LD2  P
        LDA  A,2
        CMPA A,1
        JG   LINSRT
        LDA  P
        STA  PREV
        LDA  LINK,2
        STA  P
        JMP  LFIND
LINSRT  LDA  PREV
        JAZ  LHEAD
        LD3  PREV
        LDA  LINK,3
        STA  LINK,1
        ENTA 0,1
        STA  LINK,3
        JMP  LNEXT
LHEAD   LDA  HEAD
        STA  LINK,1
        ENTA 0,1
        STA  HEAD
LNEXT   INC1 1
        CMP1 =N=
        JLE  LINS
        LDA  HEAD
        STA  P
        ENT2 1
LWALK   LDA  P
        JAZ  LCOPY
        LD3  P
        LDA  A,3
        STA  B,2
        INC2 1
        LDA  LINK,3
        STA  P
        JMP  LWALK
LCOPY   ENT1 1
LCP     LDA  B,1
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  LCP
        HLT
HEAD    CON  0
P       CON  0
PREV    CON  0
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
C256    CON  256
        END  START
''',
  ),
  GalleryProgram(
    id: 'quicksort',
    section: '5.2.2',
    title: 'Quicksort',
    description:
        'Partition around a pivot (A[hi]), then recurse — here iteratively, '
        'with an explicit (lo,hi) stack and Lomuto partition. Fast on average '
        '(~26,000u, a third of bubble). Watch the partition sweep, then the '
        'two halves resolve independently.',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Quicksort (TAOCP 5.2.2): iterative, explicit (lo,hi) stack, Lomuto.
A       EQU  1000
STKLO   EQU  2000
STKHI   EQU  2300
N       EQU  100
        ORIG 3000
START   ENT1 1
FILL    LDA  SEED
        MUL  MULT
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  C256
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  FILL
        ENT5 0
        ENTA 1
        STA  STKLO
        ENTA N
        STA  STKHI
        INC5 1
QMAIN   J5Z  QDONE          is  stack empty  =>  done
        DEC5 1
        LDA  STKLO,5
        STA  LO
        LDA  STKHI,5
        STA  HI
        LDA  LO
        CMPA HI
        JGE  QMAIN          is  0- or 1-element range
        LD1  HI
        LDA  A,1
        STA  PIVOT          is  pivot = A[hi]
        LDA  LO
        DECA 1
        STA  IIDX
        LD2  LO
PLOOP   ENTA 0,2
        SUB  HI
        JANN PDONE
        LDA  A,2
        CMPA PIVOT
        JG   PNEXT
        LDA  IIDX
        INCA 1
        STA  IIDX
        LD3  IIDX
        LDA  A,3
        STA  TMP
        LDA  A,2
        STA  A,3
        LDA  TMP
        STA  A,2           is  swap A[i], A[j]
PNEXT   INC2 1
        JMP  PLOOP
PDONE   LDA  IIDX
        INCA 1
        STA  PIDX
        LD3  PIDX
        LD1  HI
        LDA  A,3
        STA  TMP
        LDA  A,1
        STA  A,3
        LDA  TMP
        STA  A,1           is  put pivot at its final spot
        LDA  LO
        STA  STKLO,5
        LDA  PIDX
        DECA 1
        STA  STKHI,5
        INC5 1             is  push (lo, p-1)
        LDA  PIDX
        INCA 1
        STA  STKLO,5
        LDA  HI
        STA  STKHI,5
        INC5 1             is  push (p+1, hi)
        JMP  QMAIN
QDONE   HLT
LO      CON  0
HI      CON  0
PIVOT   CON  0
IIDX    CON  0
PIDX    CON  0
TMP     CON  0
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
C256    CON  256
        END  START
''',
  ),
  GalleryProgram(
    id: 'selection-sort',
    section: '5.2.3',
    title: 'Straight Selection Sort',
    description:
        'For each position, scan the rest of the array for the minimum and '
        'swap it in. Only n−1 swaps, but n²/2 comparisons — O(n²) and slow '
        '(~56,000u). Watch the read-cursor sweep the unsorted tail each pass.',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Straight selection sort (TAOCP 5.2.3).
A       EQU  1000
N       EQU  100
        ORIG 3000
START   ENT1 1
FILL    LDA  SEED
        MUL  MULT
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  C256
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  FILL
        ENT1 1
SILOOP  ENTA 0,1
        DECA N
        JANN SDONE
        ENT3 0,1           is  min = i
        ENT2 1,1           is  j = i+1
SJLOOP  ENTA 0,2
        DECA N
        JAP  SSWAP
        LDA  A,2
        CMPA A,3
        JGE  SJNEXT
        ENT3 0,2           is  new minimum at j
SJNEXT  INC2 1
        JMP  SJLOOP
SSWAP   LDA  A,1
        STA  TMP
        LDA  A,3
        STA  A,1
        LDA  TMP
        STA  A,3           is  swap A[i], A[min]
        INC1 1
        JMP  SILOOP
SDONE   HLT
TMP     CON  0
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
C256    CON  256
        END  START
''',
  ),
  GalleryProgram(
    id: 'merge-two-way',
    section: '5.2.4',
    title: 'Two-Way Merge Sort',
    description:
        'Bottom-up merge: merge adjacent runs of width 1, then 2, 4, … into a '
        'scratch array and copy back, doubling the width each pass. Steady '
        'O(n log n) (~29,000u). The bars resolve in ever-larger sorted blocks.',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Straight two-way merge sort (TAOCP 5.2.4), bottom-up with a scratch array.
A       EQU  1000
B       EQU  1200
N       EQU  100
        ORIG 3000
START   ENT1 1
FILL    LDA  SEED
        MUL  MULT
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  C256
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  FILL
        ENTA 1
        STA  WID           is  run width w = 1
MWLOOP  LDA  WID
        CMPA =N=
        JGE  MDONE
        ENTA 1
        STA  LO
MFLOOP  LDA  LO
        CMPA =N=
        JG   MCOPYB
        LDA  LO
        ADD  WID
        DECA 1
        STA  MID
        LDA  MID
        CMPA =N=
        JLE  MM1
        LDA  =N=
        STA  MID
MM1     LDA  LO
        ADD  WID
        ADD  WID
        DECA 1
        STA  HI
        LDA  HI
        CMPA =N=
        JLE  MM2
        LDA  =N=
        STA  HI
MM2     LD1  LO
        LDA  MID
        INCA 1
        STA  JJ
        LD2  JJ
        LD3  LO
MMERGE  CMP1 MID
        JG   MTAKEJ
        CMP2 HI
        JG   MTAKEI
        LDA  A,1
        CMPA A,2
        JG   MTAKEJ
MTAKEI  LDA  A,1
        STA  B,3
        INC1 1
        JMP  MMSTEP
MTAKEJ  LDA  A,2
        STA  B,3
        INC2 1
MMSTEP  INC3 1
        CMP1 MID
        JLE  MMERGE
        CMP2 HI
        JLE  MMERGE
        LDA  LO
        ADD  WID
        ADD  WID
        STA  LO
        JMP  MFLOOP
MCOPYB  ENT1 1
MCP     LDA  B,1
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  MCP
        LDA  WID
        ADD  WID
        STA  WID           is  double the run width
        JMP  MWLOOP
MDONE   HLT
WID     CON  0
LO      CON  0
MID     CON  0
HI      CON  0
JJ      CON  0
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
C256    CON  256
        END  START
''',
  ),
  GalleryProgram(
    id: 'natural-merge',
    section: '5.2.4',
    title: 'Natural Merge Sort',
    description:
        'Like two-way merge, but it detects the ascending runs already present '
        'in the data instead of using fixed widths — so partly-ordered input '
        'sorts in fewer passes. Merges natural runs into a scratch array and '
        'copies back until one run remains (~28,000u).',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Natural merge sort (TAOCP 5.2.4): merge the data's own ascending runs.
A       EQU  1000
B       EQU  1200
N       EQU  100
        ORIG 3000
START   ENT1 1
FILL    LDA  SEED
        MUL  MULT
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  C256
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  FILL
NPASS   ENTA 0
        STA  RUNS
        ENTA 1
        STA  II
NLOOP   LDA  II
        CMPA =N=
        JG   NENDP
        LD1  II
NE1     ENTA 0,1
        DECA N
        JANN NE1D
        LDA  A+1,1
        CMPA A,1
        JL   NE1D
        INC1 1
        JMP  NE1
NE1D    ST1  E1            is  end of the first run
        ENTA 0,1
        DECA N
        JANN NSINGLE
        INC1 1
NE2     ENTA 0,1
        DECA N
        JANN NE2D
        LDA  A+1,1
        CMPA A,1
        JL   NE2D
        INC1 1
        JMP  NE2
NE2D    ST1  E2            is  end of the second run
        LD1  II
        LDA  E1
        INCA 1
        STA  JJ
        LD2  JJ
        LD3  II
NMERGE  CMP1 E1
        JG   NTAKEQ
        CMP2 E2
        JG   NTAKEP
        LDA  A,1
        CMPA A,2
        JG   NTAKEQ
NTAKEP  LDA  A,1
        STA  B,3
        INC1 1
        JMP  NMSTEP
NTAKEQ  LDA  A,2
        STA  B,3
        INC2 1
NMSTEP  INC3 1
        CMP1 E1
        JLE  NMERGE
        CMP2 E2
        JLE  NMERGE
        LDA  RUNS
        INCA 1
        STA  RUNS
        LDA  E2
        INCA 1
        STA  II
        JMP  NLOOP
NSINGLE LD1  II
NSC     LDA  A,1
        STA  B,1
        INC1 1
        ENTA 0,1
        DECA N
        JANP NSC
        LDA  RUNS
        INCA 1
        STA  RUNS
NENDP   ENT1 1
NCP     LDA  B,1
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  NCP
        LDA  RUNS
        DECA 1
        JANP NDONE         is  one run left  =>  sorted
        JMP  NPASS
NDONE   HLT
RUNS    CON  0
II      CON  0
E1      CON  0
E2      CON  0
JJ      CON  0
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
C256    CON  256
        END  START
''',
  ),
  GalleryProgram(
    id: 'radix-sort',
    section: '5.2.5',
    title: 'Radix / Distribution Sort',
    description:
        'Distribution counting (TAOCP 5.2.5): count how many of each value '
        '(0–255) occur, turn the counts into positions, then place each '
        'element directly. No comparisons — O(n), the fastest here by far '
        '(~11,800u). The array snaps sorted during the final placement.',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Distribution counting sort (TAOCP 5.2.5), values 0..255.
A       EQU  1000
COUNT   EQU  1200
B       EQU  1500
N       EQU  100
        ORIG 3000
START   ENT1 1
FILL    LDA  SEED
        MUL  MULT
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  C256
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  FILL
        ENT1 0
RZ      ENTA 0
        STA  COUNT,1
        INC1 1
        ENTA 0,1
        DECA 256
        JAN  RZ            is  clear COUNT[0..255]
        ENT1 1
RC      LD2  A,1
        LDA  COUNT,2
        INCA 1
        STA  COUNT,2       is  tally each value
        INC1 1
        CMP1 =N=
        JLE  RC
        ENT1 1
RS      LDA  COUNT-1,1
        ADD  COUNT,1
        STA  COUNT,1       is  running sums -> end positions
        INC1 1
        ENTA 0,1
        DECA 256
        JAN  RS
        LD1  =N=
RD      LD2  A,1
        LDA  COUNT,2
        STA  POS
        LD3  POS
        LDA  A,1
        STA  B,3           is  place A[i] at its counted position
        LDA  COUNT,2
        DECA 1
        STA  COUNT,2
        DEC1 1
        J1P  RD
        ENT1 1
RCP     LDA  B,1
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  RCP
        HLT
POS     CON  0
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
C256    CON  256
        END  START
''',
  ),
  GalleryProgram(
    id: 'tape-merge-sort',
    section: '5.4',
    title: 'External Sort — Balanced Tape Merge',
    description:
        'External sorting on tapes (TAOCP 5.4): distribute length-1 runs '
        'across two tapes, then merge pairs of runs back and forth between '
        'two tape-pairs, doubling the run length each pass, rewinding between '
        'passes. Tape units are chosen at run time by self-modifying the '
        'IN/OUT/IOC instructions. Data lives on the tapes during the sort and '
        'is read back to the array at the end. (Each tape record is one word '
        'here, simplified from MIX’s 100-word blocks.)',
    arrayBase: 1001,
    arrayLength: 16,
    source: '''
* Balanced two-way merge sort on four tapes (TAOCP 5.4). N a power of two.
* Tape units are selected at run time by patching the F field (STA lbl(4:4)).
A       EQU  1000
ABUF    EQU  1100
BBUF    EQU  1120
N       EQU  16
        ORIG 3000
START   ENT1 1
FILL    LDA  SEED
        MUL  MULT
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  C256
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  FILL
* distribute length-1 runs alternately to tapes 0 and 1
        ENT1 1
        ENTA 0
        STA  OTOG
DIST    LDA  A,1
        STA  WRBUF
        LDA  OTOG
        STA  DWR(4:4)
DWR     OUT  WRBUF(0)
        LDA  =1=
        SUB  OTOG
        STA  OTOG
        INC1 1
        CMP1 =N=
        JLE  DIST
        ENTA 1
        STA  L
        ENTA 0
        STA  IU0
        ENTA 1
        STA  IU1
        ENTA 2
        STA  OU0
        ENTA 3
        STA  OU1
PASS    IOC  0(0)
        IOC  0(1)
        IOC  0(2)
        IOC  0(3)
        LDA  IU0
        STA  RDA(4:4)
        LDA  IU1
        STA  RDB(4:4)
        ENTA 0
        STA  OTOG
        LDA  =N=
        STA  T
        LDA  L
        ADD  L
        STA  T2
        ENTA 0
        LDX  T
        DIV  T2
        STA  NP            is  number of run-pairs this pass
        ENT4 0
MPAIR   ENTA 0,4
        SUB  NP
        JANN NEXTP
        LDA  OTOG
        JAZ  USEO0
        LDA  OU1
        JMP  SETW
USEO0   LDA  OU0
SETW    STA  WR(4:4)
        JMP  MERGE
        LDA  =1=
        SUB  OTOG
        STA  OTOG
        INC4 1
        JMP  MPAIR
NEXTP   LDA  IU0
        STA  TMP0
        LDA  IU1
        STA  TMP1
        LDA  OU0
        STA  IU0
        LDA  OU1
        STA  IU1
        LDA  TMP0
        STA  OU0
        LDA  TMP1
        STA  OU1
        LDA  L
        ADD  L
        STA  L
        CMPA =N=
        JL   PASS
* finish: the sorted run is on IU0 -> read it back into A
        LDA  IU0
        STA  FRD(4:4)
        LDA  IU0
        STA  FIOC(4:4)
FIOC    IOC  0(0)
        ENT1 1
FLOOP   NOP
FRD     IN   A,1
        INC1 1
        CMP1 =N=
        JLE  FLOOP
        HLT
* MERGE: merge one L-run from each input tape onto the output tape
MERGE   STJ  MEXIT
        ENT5 0
RDA     IN   ABUF,5
        INC5 1
        ENTA 0,5
        SUB  L
        JAN  RDA
        ENT5 0
RDB     IN   BBUF,5
        INC5 1
        ENTA 0,5
        SUB  L
        JAN  RDB
        ENT1 0
        ENT2 0
MMG     ENTA 0,1
        SUB  L
        JANN TAKEB
        ENTA 0,2
        SUB  L
        JANN TAKEA
        LDA  ABUF,1
        CMPA BBUF,2
        JG   TAKEB
TAKEA   LDA  ABUF,1
        STA  WRBUF
        INC1 1
        JMP  DOOUT
TAKEB   LDA  BBUF,2
        STA  WRBUF
        INC2 1
DOOUT   NOP
WR      OUT  WRBUF(0)
        ENTA 0,1
        SUB  L
        JAN  MMG
        ENTA 0,2
        SUB  L
        JAN  MMG
MEXIT   JMP  *
L       CON  0
IU0     CON  0
IU1     CON  0
OU0     CON  0
OU1     CON  0
OTOG    CON  0
NP      CON  0
T       CON  0
T2      CON  0
TMP0    CON  0
TMP1    CON  0
WRBUF   CON  0
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
C256    CON  256
        END  START
''',
  ),
  GalleryProgram(
    id: 'sequential-search',
    section: '6.1',
    title: 'Sequential Search',
    description:
        'Fills a sorted ramp A[i] = i, then scans left to right for key 73, '
        'leaving its index in RESULT. O(n) — the read-cursor simply marches '
        'along the bars until it lands on the target.',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Sequential search (TAOCP 6.1). Ramp A[i] = i; find KEY, index in RESULT.
A       EQU  1000
N       EQU  100
        ORIG 3000
START   ENT1 1
RFILL   ENTA 0,1
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  RFILL
        ENT1 1
SLOOP   LDA  A,1
        CMPA KEY
        JE   SFOUND
        INC1 1
        CMP1 =N=
        JLE  SLOOP
        ENTA 0
        STA  RESULT
        HLT
SFOUND  ST1  RESULT
        HLT
KEY     CON  73
RESULT  CON  0
        END  START
''',
  ),
  GalleryProgram(
    id: 'binary-search',
    section: '6.2.1',
    title: 'Binary Search',
    description:
        'On the sorted ramp, repeatedly halve the [lo,hi] range: probe the '
        'midpoint, then keep the half that could contain key 73. O(log n) — '
        'watch the probes converge in a handful of steps. Index in RESULT.',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Binary search (TAOCP 6.2.1). Ramp A[i] = i; index of KEY in RESULT.
A       EQU  1000
N       EQU  100
        ORIG 3000
START   ENT1 1
RFILL   ENTA 0,1
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  RFILL
        ENTA 1
        STA  LO
        ENTA N
        STA  HI
BLOOP   LDA  LO
        CMPA HI
        JG   BNONE
        LDA  LO
        ADD  HI
        STA  SUM
        ENTA 0
        LDX  SUM
        DIV  TWO
        STA  MID           is  mid = (lo+hi)/2
        LD1  MID
        LDA  A,1
        CMPA KEY
        JE   BFOUND
        JG   BHI
        LDA  MID
        INCA 1
        STA  LO            is  A[mid] < key: search right
        JMP  BLOOP
BHI     LDA  MID
        DECA 1
        STA  HI            is  A[mid] > key: search left
        JMP  BLOOP
BFOUND  ST1  RESULT
        HLT
BNONE   ENTA 0
        STA  RESULT
        HLT
LO      CON  0
HI      CON  0
SUM     CON  0
MID     CON  0
TWO     CON  2
KEY     CON  73
RESULT  CON  0
        END  START
''',
  ),
  GalleryProgram(
    id: 'uniform-search',
    section: '6.2.1',
    title: 'Uniform Binary Search',
    description:
        'A binary search whose probe steps are fixed powers of two — first '
        'the largest 2ᵏ ≤ N, then halving — so it never computes (lo+hi)/2. '
        'Finds the largest index with A[i] ≤ key, then checks equality. '
        'Index of 73 in RESULT.',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Uniform binary search (TAOCP 6.2.1), power-of-two steps. Ramp A[i] = i.
A       EQU  1000
N       EQU  100
        ORIG 3000
START   ENT1 1
RFILL   ENTA 0,1
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  RFILL
        ENTA 1
        STA  STEP
US1     LDA  STEP
        ADD  STEP
        CMPA =N=
        JG   US1D
        STA  STEP
        JMP  US1           is  STEP = largest power of 2 <= N
US1D    ENT1 0
USL     LDA  STEP
        JAZ  USDONE
        ENTA 0,1
        ADD  STEP
        CMPA =N=
        JG   USHALF
        STA  IPS
        LD2  IPS
        LDA  A,2
        CMPA KEY
        JG   USHALF
        LD1  IPS           is  A[i+step] <= key: advance i
USHALF  LDA  STEP
        STA  T
        ENTA 0
        LDX  T
        DIV  TWO
        STA  STEP          is  halve the step
        JMP  USL
USDONE  ENTA 0,1
        JAZ  USNONE
        LDA  A,1
        CMPA KEY
        JE   USFOUND
USNONE  ENTA 0
        STA  RESULT
        HLT
USFOUND ST1  RESULT
        HLT
STEP    CON  0
IPS     CON  0
T       CON  0
TWO     CON  2
KEY     CON  73
RESULT  CON  0
        END  START
''',
  ),
  GalleryProgram(
    id: 'tree-search',
    section: '6.2.2',
    title: 'Binary Tree Search & Insertion',
    description:
        'Inserts 100 random keys into a binary search tree (LEFT/RIGHT link '
        'arrays), then searches for one that is present, setting FOUND = 1. '
        'The bar chart shows the keys in insertion order; the search reads '
        'flash along the tree path.',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Binary tree search and insertion (TAOCP 6.2.2).
A       EQU  1000
LEFT    EQU  1200
RIGHT   EQU  1400
N       EQU  100
        ORIG 3000
START   ENT1 1
FILL    LDA  SEED
        MUL  MULT
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  C256
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  FILL
        LDA  A+50
        STA  TARGET        is  search for a key we inserted
        ENTA 0
        STA  ROOT
        ENT1 1
BINS    LDA  ROOT
        JAZ  BSROOT
        LD2  ROOT
BDESC   LDA  A,1
        CMPA A,2
        JL   BLEFT
        LDA  RIGHT,2
        JAZ  BINSR
        LD2  RIGHT,2
        JMP  BDESC
BLEFT   LDA  LEFT,2
        JAZ  BINSL
        LD2  LEFT,2
        JMP  BDESC
BINSR   ENTA 0,1
        STA  RIGHT,2
        JMP  BNEXT
BINSL   ENTA 0,1
        STA  LEFT,2
        JMP  BNEXT
BSROOT  ENTA 0,1
        STA  ROOT
BNEXT   INC1 1
        CMP1 =N=
        JLE  BINS
        LDA  ROOT
        STA  P
BSRCH   LDA  P
        JAZ  BNONE
        LD2  P
        LDA  TARGET
        CMPA A,2
        JE   BFOUND
        JL   BSL
        LDA  RIGHT,2
        STA  P
        JMP  BSRCH
BSL     LDA  LEFT,2
        STA  P
        JMP  BSRCH
BFOUND  ENTA 1
        STA  FOUND
        HLT
BNONE   ENTA 0
        STA  FOUND
        HLT
ROOT    CON  0
P       CON  0
TARGET  CON  0
FOUND   CON  0
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
C256    CON  256
        END  START
''',
  ),
  GalleryProgram(
    id: 'hash-chaining',
    section: '6.4',
    title: 'Hashing — Separate Chaining',
    description:
        'Hashes 100 random keys into 16 buckets (key mod 16), each bucket a '
        'linked list, then searches one bucket for a present key (FOUND = 1). '
        'Near-constant time regardless of table order.',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Hashing with separate chaining (TAOCP 6.4). 16 buckets, key mod 16.
A       EQU  1000
HASH    EQU  1200
NEXT    EQU  1300
N       EQU  100
        ORIG 3000
START   ENT1 1
FILL    LDA  SEED
        MUL  MULT
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  C256
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  FILL
        LDA  A+50
        STA  TARGET
        ENT1 1
HINS    LDA  A,1
        STA  T
        ENTA 0
        LDX  T
        DIV  M16
        STX  H             is  bucket = key mod 16
        LD2  H
        LDA  HASH,2
        STA  NEXT,1
        ENTA 0,1
        STA  HASH,2        is  prepend node to the bucket list
        INC1 1
        CMP1 =N=
        JLE  HINS
        LDA  TARGET
        STA  T
        ENTA 0
        LDX  T
        DIV  M16
        STX  H
        LD2  H
        LDA  HASH,2
        STA  P
HSRCH   LDA  P
        JAZ  HNONE
        LD3  P
        LDA  A,3
        CMPA TARGET
        JE   HFOUND
        LDA  NEXT,3
        STA  P             is  walk the chain
        JMP  HSRCH
HFOUND  ENTA 1
        STA  FOUND
        HLT
HNONE   ENTA 0
        STA  FOUND
        HLT
T       CON  0
H       CON  0
P       CON  0
TARGET  CON  0
FOUND   CON  0
M16     CON  16
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
C256    CON  256
        END  START
''',
  ),
  GalleryProgram(
    id: 'hash-linear',
    section: '6.4',
    title: 'Hashing — Linear Probing',
    description:
        'Open addressing: hash 100 random keys into a 128-slot table (key mod '
        '128) and resolve collisions by probing the next slot. Search walks '
        'the same probe sequence until it hits the key or an empty slot '
        '(FOUND = 1).',
    arrayBase: 1001,
    arrayLength: 100,
    source: '''
* Hashing with linear probing (TAOCP 6.4). 128-slot open-addressed table.
A       EQU  1000
TABLE   EQU  1200
N       EQU  100
        ORIG 3000
START   ENT1 1
FILL    LDA  SEED
        MUL  MULT
        STX  SEED
        LDA  SEED
        ADD  INCR
        STA  SEED
        MUL  C256
        STA  A,1
        INC1 1
        CMP1 =N=
        JLE  FILL
        LDA  A+50
        STA  TARGET
        ENT1 1
LINS    LDA  A,1
        STA  T
        ENTA 0
        LDX  T
        DIV  M128
        STX  SLOT          is  slot = key mod 128
LPROBE  LD2  SLOT
        LDA  TABLE,2
        JAZ  LPUT
        LDA  SLOT
        INCA 1
        STA  SLOT
        CMPA M128
        JL   LPROBE
        ENTA 0
        STA  SLOT          is  wrap around
        JMP  LPROBE
LPUT    ENTA 0,1
        STA  TABLE,2
        INC1 1
        CMP1 =N=
        JLE  LINS
        LDA  TARGET
        STA  T
        ENTA 0
        LDX  T
        DIV  M128
        STX  SLOT
LSRCH   LD2  SLOT
        LDA  TABLE,2
        JAZ  LNONE
        LD3  TABLE,2
        LDA  A,3
        CMPA TARGET
        JE   LFOUND
        LDA  SLOT
        INCA 1
        STA  SLOT
        CMPA M128
        JL   LSRCH
        ENTA 0
        STA  SLOT
        JMP  LSRCH
LFOUND  ENTA 1
        STA  FOUND
        HLT
LNONE   ENTA 0
        STA  FOUND
        HLT
T       CON  0
SLOT    CON  0
TARGET  CON  0
FOUND   CON  0
M128    CON  128
SEED    CON  1
MULT    CON  1664525
INCR    CON  1013904223
C256    CON  256
        END  START
''',
  ),
  GalleryProgram(
    id: 'mp-sub',
    section: '4.3.1',
    title: 'Multiple-Precision Subtraction',
    description:
        'Subtracts two four-digit big integers (radix 10000, most-significant '
        'first) digit by digit, propagating a borrow detected from the sign '
        'of each difference. Computes 10¹² − 1 = 999,999,999,999; result at W '
        '(1200).',
    source: '''
* Multiple-precision subtraction (TAOCP 4.3.1, Algorithm S). W = U - V.
* Radix 10000, big-endian; borrow is the sign of U[i]-V[i]-borrow.
U       EQU  1000
V       EQU  1100
W       EQU  1200
NW      EQU  4
        ORIG 3000
START   ENTA 0
        STA  BORROW
        ENT1 NW-1
SLOOP   LDA  U,1
        SUB  V,1
        SUB  BORROW
        ENT3 0
        JANN SPOS          is  difference >= 0: no borrow
        ADD  RC            is  else add the radix and borrow
        ENT3 1
SPOS    STA  W,1
        ST3  BORROW
        DEC1 1
        J1NN SLOOP
        HLT
BORROW  CON  0
RC      CON  10000
        ORIG U
        CON  1
        CON  0
        CON  0
        CON  0
        ORIG V
        CON  0
        CON  0
        CON  0
        CON  1
        END  START
''',
  ),
  GalleryProgram(
    id: 'mp-mul',
    section: '4.3.1',
    title: 'Multiple-Precision Multiplication',
    description:
        'Schoolbook long multiplication of two big integers (radix 10000, '
        'least-significant first): each digit product plus the running column '
        'value and carry, split with a DIV by the radix. 12,345,678 × '
        '87,654,321; four-digit product at W (1200).',
    source: '''
* Multiple-precision multiplication (TAOCP 4.3.1, Algorithm M). W = U * V.
* Radix 10000, little-endian.
U       EQU  1000
V       EQU  1100
W       EQU  1200
MM      EQU  2
NN      EQU  2
MPN     EQU  4
        ORIG 3000
START   ENT1 0
MZ      ENTA 0
        STA  W,1
        INC1 1
        ENTA 0,1
        DECA MPN
        JAN  MZ
        ENT1 0
MILOOP  ENTA 0
        STA  CARRY
        ENT2 0
MJLOOP  LDA  U,1
        MUL  V,2           is  U[i]*V[j]
        STX  PROD
        ENTA 0,1
        INCA 0,2
        STA  IDX
        LD3  IDX
        LDA  PROD
        ADD  W,3
        ADD  CARRY         is  + column + carry
        STA  T
        ENTA 0
        LDX  T
        DIV  RC
        STX  W,3           is  digit = t mod radix
        STA  CARRY         is  carry = t div radix
        INC2 1
        ENTA 0,2
        DECA NN
        JAN  MJLOOP
        ENTA 0,1
        INCA NN
        STA  IDX
        LD3  IDX
        LDA  CARRY
        STA  W,3
        INC1 1
        ENTA 0,1
        DECA MM
        JAN  MILOOP
        HLT
CARRY   CON  0
PROD    CON  0
IDX     CON  0
T       CON  0
RC      CON  10000
        ORIG U
        CON  5678
        CON  1234
        ORIG V
        CON  4321
        CON  8765
        END  START
''',
  ),
  GalleryProgram(
    id: 'mp-div',
    section: '4.3.1',
    title: 'Multiple-Precision Short Division',
    description:
        'Divides a big integer (radix 10000, most-significant first) by a '
        'single-digit divisor, carrying the remainder into each next digit — '
        '123,456,789 ÷ 7. Quotient at Q (1100), remainder in REMOUT. (The '
        'full multi-digit divisor, Algorithm D, is a larger follow-up.)',
    source: '''
* Multiple-precision short division (TAOCP 4.3.1): big integer / one digit.
* Radix 10000, big-endian.
U       EQU  1000
Q       EQU  1100
MW      EQU  3
        ORIG 3000
START   ENTA 0
        STA  REM
        ENT1 0
DLOOP   LDA  REM
        MUL  RC            is  remainder * radix ...
        STX  T
        LDA  T
        ADD  U,1           is  ... + next digit
        STA  T
        ENTA 0
        LDX  T
        DIV  DD
        STA  Q,1           is  quotient digit
        STX  REM           is  new remainder
        INC1 1
        ENTA 0,1
        DECA MW
        JAN  DLOOP
        LDA  REM
        STA  REMOUT
        HLT
REM     CON  0
REMOUT  CON  0
T       CON  0
RC      CON  10000
DD      CON  7
        ORIG U
        CON  1
        CON  2345
        CON  6789
        END  START
''',
  ),
  GalleryProgram(
    id: 'radix-conversion',
    section: '4.4',
    title: 'Radix Conversion',
    description:
        'Converts a binary word value to its decimal digits by repeated '
        'division by 10, collecting remainders (least-significant digit '
        'first). 12345 → digits 5,4,3,2,1 at DIG; the count is in NDIG.',
    source: '''
* Radix conversion (TAOCP 4.4): a word value to base-10 digits.
        ORIG 3000
START   LDA  VAL
        STA  W
        ENT1 0
RCL     LDA  W
        JAZ  RCDONE        is  value exhausted
        STA  T
        ENTA 0
        LDX  T
        DIV  TEN
        STA  W             is  value = value / 10
        STX  DIG,1         is  next digit = value mod 10
        INC1 1
        JMP  RCL
RCDONE  ST1  NDIG
        HLT
VAL     CON  12345
W       CON  0
T       CON  0
NDIG    CON  0
TEN     CON  10
DIG     CON  0
        END  START
''',
  ),
  GalleryProgram(
    id: 'poly-derivative',
    section: '4.6.1',
    title: 'Polynomial Derivative',
    description:
        'Differentiates a polynomial stored as a coefficient array: the '
        'derivative coefficient D[i] = (i+1)·C[i+1]. For 3x³ + 2x² + 5x + 7 '
        'it produces 9x² + 4x + 5, with the new coefficients at D (1100).',
    source: '''
* Polynomial derivative (TAOCP 4.6.1). C[i] = coeff of x^i.
C       EQU  1000
D       EQU  1100
DEG     EQU  3
        ORIG 3000
START   ENT1 0
PDL     ENTA 0,1
        DECA DEG
        JANN PDDONE
        ENTA 1,1
        STA  T             is  multiplier (i+1)
        LDA  C+1,1
        MUL  T             is  D[i] = C[i+1] * (i+1)
        STX  D,1
        INC1 1
        JMP  PDL
PDDONE  HLT
T       CON  0
        ORIG C
        CON  7
        CON  5
        CON  2
        CON  3
        END  START
''',
  ),
  GalleryProgram(
    id: 'poly-division',
    section: '4.6.1',
    title: 'Polynomial Division',
    description:
        'Long-divides one polynomial by a monic divisor. For (x³ − 6x² + 11x '
        '− 6) ÷ (x − 1) it yields quotient x² − 5x + 6 (at Q) and remainder 0 '
        '(at R), subtracting a shifted multiple of the divisor each step.',
    source: '''
* Polynomial long division by a monic divisor (TAOCP 4.6.1). P / DPOLY.
C       EQU  1000
DPOLY   EQU  1100
Q       EQU  1200
R       EQU  1300
PM      EQU  3
DD      EQU  1
        ORIG 3000
START   ENT1 0
PCP     LDA  C,1
        STA  R,1           is  remainder starts as a copy of P
        INC1 1
        ENTA 0,1
        DECA PM
        JANP PCP
        ENT1 PM
DVL     ENTA 0,1
        DECA DD
        JAN  DVDONE
        LDA  R,1
        STA  QCUR          is  quotient coeff (divisor is monic)
        ENTA 0,1
        DECA DD
        STA  KMD
        LD2  KMD
        LDA  QCUR
        STA  Q,2
        ENT3 0
DJ      ENTA 0,3
        DECA DD
        JANP DJC
        JMP  DNEXT
DJC     LDA  DPOLY,3
        MUL  QCUR
        STX  PROD
        ENTA 0,2
        INCA 0,3
        STA  IDX
        LD4  IDX
        LDA  R,4
        SUB  PROD          is  subtract q * divisor, shifted
        STA  R,4
        INC3 1
        JMP  DJ
DNEXT   DEC1 1
        JMP  DVL
DVDONE  HLT
QCUR    CON  0
KMD     CON  0
PROD    CON  0
IDX     CON  0
        ORIG C
        CON  -6
        CON  11
        CON  -6
        CON  1
        ORIG DPOLY
        CON  -1
        CON  1
        END  START
''',
  ),
  GalleryProgram(
    id: 'float-horner',
    section: '4.6.4',
    title: 'Floating Point — Horner’s Rule',
    description:
        'Evaluates the polynomial 2x³ − 3x² + 5 at x = 2 by Horner’s method, '
        'using the floating-point instructions FMUL and FADD: start with the '
        'top coefficient and repeatedly multiply by x and add the next '
        'coefficient. The answer, 9.0, ends in RESULT.',
    source: '''
* Horner's rule with floating point (TAOCP 4.6.4 idea).
* p(x) = 2x^3 - 3x^2 + 0x + 5, evaluated at x = 2.  Result 9.0 in RESULT.
N       EQU  3
        ORIG 3000
START   LDA  COEF          is  r = leading coefficient
        ENT1 1
LOOP    FMUL X             is  r = r * x
        FADD COEF,1        is  r = r + next coefficient
        INC1 1
        CMP1 =N=
        JLE  LOOP
        STA  RESULT
        HLT
X       CON  2.0
COEF    CON  2.0
        CON  -3.0
        CON  0.0
        CON  5.0
RESULT  CON  0.0
        END  START
''',
  ),
  GalleryProgram(
    id: 'float-average',
    section: '4.2.1',
    title: 'Floating Point — Average',
    description:
        'Sums five floating-point numbers with FADD, then divides by the '
        'count with FDIV. The mean of 1.5, 2.5, 3.5, 4.5, 6.0 is 3.6, left '
        'in RESULT — a tour of the floating-point add and divide.',
    source: '''
* Floating-point average of N numbers (uses FADD and FDIV).
N       EQU  5
        ORIG 3000
START   LDA  ZERO          is  running sum = 0.0
        ENT1 0
LOOP    FADD DATA,1        is  sum += DATA[i]
        INC1 1
        CMP1 =N=
        JL   LOOP
        FDIV COUNT         is  sum / N
        STA  RESULT
        HLT
ZERO    CON  0.0
DATA    CON  1.5
        CON  2.5
        CON  3.5
        CON  4.5
        CON  6.0
COUNT   CON  5.0
RESULT  CON  0.0
        END  START
''',
  ),
  GalleryProgram(
    id: 'program-a',
    section: '1.3.3',
    title: 'Program A — Multiply Permutations (cycle form)',
    description:
        'Reads a product of cycles written as text — "(ABC)(AB)" — from '
        'memory, one MIX character at a time, and composes the cycles '
        'left-to-right into a single permutation. The result maps each '
        'letter, stored by character code in Q[] at 700 (A→A, B→C, C→B '
        'for this input). A reconstruction of §1.3.3’s cycle-notation idea.',
    source: '''
* Program A (spirit of TAOCP 1.3.3): multiply permutations in cycle form.
* Reads the '.'-terminated cycle string INPUT (MIX characters), composes
* the cycles left-to-right, and leaves the product in Q[code] at QBASE.
INPUT   EQU  500
CHARS   EQU  600
QBASE   EQU  700
NBASE   EQU  800
NW      EQU  2
        ORIG 3000
* ---- unpack the packed input words into one char per cell ----
START   ENT1 0
        ENT2 0
UNPK    LDA  INPUT,1(1:1)
        STA  CHARS,2
        INC2 1
        LDA  INPUT,1(2:2)
        STA  CHARS,2
        INC2 1
        LDA  INPUT,1(3:3)
        STA  CHARS,2
        INC2 1
        LDA  INPUT,1(4:4)
        STA  CHARS,2
        INC2 1
        LDA  INPUT,1(5:5)
        STA  CHARS,2
        INC2 1
        INC1 1
        CMP1 =NW=
        JL   UNPK
* ---- Q := the identity permutation ----
        ENT3 0
QINIT   ENTA 0,3
        STA  QBASE,3
        INC3 1
        CMP3 =56=
        JL   QINIT
* ---- scan the formula character by character ----
        ENT1 0
LOOP    LDA  CHARS,1
        JAZ  SKIP         is  blank: ignore
        CMPA =40=
        JE   DONE         is  '.' : end of formula
        CMPA =42=
        JE   OPEN         is  '(' : begin a cycle
        CMPA =43=
        JE   CLOSE        is  ')' : close and apply the cycle
* ---- a cycle symbol ----
        LDX  HASPREV
        JXNZ HAVEP
        STA  FIRST        is  first symbol of this cycle
        STA  PREV
        ENTX 1
        STX  HASPREV
        JMP  SKIP
HAVEP   LD2  PREV
        STA  NBASE,2      is  NEXT[prev] = this symbol
        STA  PREV
        JMP  SKIP
* ---- '(' : reset NEXT to identity, forget prev ----
OPEN    ENT3 0
OPI     ENTA 0,3
        STA  NBASE,3
        INC3 1
        CMP3 =56=
        JL   OPI
        STZ  HASPREV
        JMP  SKIP
* ---- ')' : close the cycle, then Q := thisCycle o Q ----
CLOSE   LD2  PREV
        LDA  FIRST
        STA  NBASE,2      is  NEXT[prev] = first (wrap the cycle)
        ENT3 0
APPLY   LD2  QBASE,3
        LDA  NBASE,2      is  Q[c] := NEXT[Q[c]]
        STA  QBASE,3
        INC3 1
        CMP3 =56=
        JL   APPLY
        JMP  SKIP
SKIP    INC1 1
        JMP  LOOP
DONE    HLT
FIRST   CON  0
PREV    CON  0
HASPREV CON  0
        ORIG INPUT
        ALF  "(ABC)"
        ALF  "(AB)."
        END  START
''',
  ),
];
