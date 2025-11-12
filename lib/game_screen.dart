import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  int score = 0;
  int currentRound = 0;
  bool showOverlay = false;
  bool showMenuPopup = false;
  bool showHowToPlay = false;

  final Random random = Random();
  List<Map<String, int>> rounds = [];
  List<int> currentChoices = [];
  int? answer;

  late ConfettiController _confettiController;
  late AnimationController _menuAnimController;
  late AnimationController _shakeController;
  late Animation<double> _menuScaleAnim;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _menuAnimController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _menuScaleAnim =
        CurvedAnimation(parent: _menuAnimController, curve: Curves.easeOutBack);
    _shakeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation = Tween<double>(begin: 0, end: 8)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _generateRounds();
    _loadNextRound();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _menuAnimController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // 🎯 Generate rounds
  void _generateRounds() {
    List<Map<String, int>> all = [];
    for (int a = 2; a <= 10; a++) {
      for (int b = 2; b <= 10; b++) {
        all.add({'a': a, 'b': b, 'result': a * b});
      }
    }
    all.shuffle(random);
    rounds = all.take(10).toList();
  }

  // 🔄 Load next round
  void _loadNextRound() {
    if (currentRound >= rounds.length) {
      setState(() => showOverlay = true);
      return;
    }

    int correct = rounds[currentRound]['result']!;
    Set<int> options = {correct};
    while (options.length < 3) {
      options.add(random.nextInt(90) + 1);
    }

    setState(() {
      answer = null;
      currentChoices = options.toList()..shuffle();
    });
  }

  // ✅ Check answer
  void _checkAnswer(int value) {
    int correct = rounds[currentRound]['result']!;
    if (value == correct) {
      score += 10;
      _confettiController.play();
      setState(() => answer = value);

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (currentRound + 1 >= rounds.length) {
          setState(() => showOverlay = true);
        } else {
          setState(() {
            currentRound++;
            _loadNextRound();
          });
        }
      });
    } else {
      _shakeController.forward(from: 0);
      setState(() => score = max(0, score - 5));
    }
  }

  // 🧩 Draggable number widget
  Widget _draggableNum(String img, int value) {
    return Draggable<int>(
      data: value,
      feedback: Image.asset("assets/images/$img", height: 80),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: Image.asset("assets/images/$img", height: 80),
      ),
      child: Image.asset("assets/images/$img", height: 80),
    );
  }

  // 📦 Drop target box
  Widget _dropBox() {
    return DragTarget<int>(
      onAccept: (value) => _checkAnswer(value),
      builder: (context, _, __) => Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _shakeAnimation.value *
                      sin(DateTime.now().millisecondsSinceEpoch / 50),
                  0,
                ),
                child: child,
              );
            },
            child: Image.asset("assets/images/woodbox.png", height: 90),
          ),
          if (answer != null)
            Image.asset("assets/images/$answer.png", height: 60),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int a = (currentRound < rounds.length)
        ? rounds[currentRound]['a']!
        : 1;
    final int b = (currentRound < rounds.length)
        ? rounds[currentRound]['b']!
        : 1;

    return Scaffold(
      body: Stack(
        children: [
          // 🌄 Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // 🧮 Top bar (Score + Menu)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset("assets/images/scoreplaceholder.png",
                              height: 55),
                          Positioned(
                            right: 25,
                            child: Text(
                              "Score: $score",
                              style: GoogleFonts.dynaPuff(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  const Shadow(
                                    offset: Offset(2, 2),
                                    blurRadius: 3,
                                    color: Colors.black45,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => showMenuPopup = true);
                          _menuAnimController.forward(from: 0);
                        },
                        child:
                        Image.asset("assets/images/menu.png", height: 45),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // ✨ Title & subtitle
                Text(
                  "Multiply",
                  style: GoogleFonts.dynaPuff(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Drag the correct product to the box that\nmatches each multiplication problem!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dynaPuff(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 35),

                // 🧮 Equation section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/images/$a.png", height: 85),
                    const SizedBox(width: 8),
                    Image.asset("assets/images/multiply.png", height: 45),
                    const SizedBox(width: 8),
                    Image.asset("assets/images/$b.png", height: 85),
                  ],
                ),

                const SizedBox(height: 10),

                // = and box section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/images/equal.png", height: 40),
                    const SizedBox(width: 10),
                    _dropBox(),
                  ],
                ),

                const SizedBox(height: 250),

                // 🪵 Wooden platform with choices
                Container(
                  height: 110,
                  width: 320,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/wood.png"),
                      fit: BoxFit.fill,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: currentChoices
                        .map((n) => _draggableNum("$n.png", n))
                        .toList(),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),

          // 🎉 Confetti effect
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              gravity: 0.4,
              numberOfParticles: 25,
            ),
          ),

          if (showMenuPopup) _buildMenuPopup(),
          if (showHowToPlay) _buildHowToPlayPopup(),
          if (showOverlay) _buildEndOverlay(),
        ],
      ),
    );
  }

  // 📜 Menu Popup
  Widget _buildMenuPopup() => Container(
    color: Colors.black.withOpacity(0.7),
    child: Center(
      child: ScaleTransition(
        scale: _menuScaleAnim,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => setState(() => showMenuPopup = false),
              child:
              Image.asset("assets/images/continue.png", height: 70),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  showMenuPopup = false;
                  showHowToPlay = true;
                });
              },
              child: Image.asset("assets/images/htp.png", height: 70),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset("assets/images/quit.png", height: 70),
            ),
          ],
        ),
      ),
    ),
  );

  // ❓ How to Play Popup
  Widget _buildHowToPlayPopup() => Container(
    color: Colors.black.withOpacity(0.7),
    child: Center(
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Center(
            child: Image.asset("assets/images/how.png",
                width: 300, fit: BoxFit.contain),
          ),
          Positioned(
            right: MediaQuery.of(context).size.width * 0.15,
            top: MediaQuery.of(context).size.height * 0.36,
            child: GestureDetector(
              onTap: () => setState(() => showHowToPlay = false),
              child: Image.asset("assets/images/x.png", height: 45),
            ),
          ),
        ],
      ),
    ),
  );

  // 🏁 End Overlay
  Widget _buildEndOverlay() => Container(
    color: Colors.black.withOpacity(0.7),
    child: Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset("assets/images/overlay.png",
              height: 350, width: 450),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 230),
              Text(
                "Score: $score",
                style: GoogleFonts.dynaPuff(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child:
                    Image.asset("assets/images/home.png", height: 60),
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        score = 0;
                        currentRound = 0;
                        showOverlay = false;
                        _generateRounds();
                        _loadNextRound();
                      });
                    },
                    child: Image.asset(
                        "assets/images/restart.png", height: 60),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
