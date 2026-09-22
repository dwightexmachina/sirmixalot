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
];
