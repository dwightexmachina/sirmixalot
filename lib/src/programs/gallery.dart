/// Bundled MIXAL programs from (or in the spirit of) TAOCP.
class GalleryProgram {
  final String id;
  final String section;
  final String title;
  final String description;
  final String source;

  const GalleryProgram({
    required this.id,
    required this.section,
    required this.title,
    required this.description,
    required this.source,
  });

  String get label => '§$section · $title';
}

const List<GalleryProgram> gallery = [
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
