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
];
