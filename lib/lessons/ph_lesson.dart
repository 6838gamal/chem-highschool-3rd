import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../constants.dart';

enum ReactionState { idle, forward, reverse }

enum ReactionType {
  ammoniaSalt,
  acidWater,
}

class HamoothWaAsasPage extends StatefulWidget {
  const HamoothWaAsasPage({super.key});

  @override
  State<HamoothWaAsasPage> createState() => _HamoothWaAsasPageState();
}

class _HamoothWaAsasPageState extends State<HamoothWaAsasPage> {
  final Random random = Random();

  ReactionState state = ReactionState.idle;
  ReactionType selectedReaction = ReactionType.ammoniaSalt;

  double temperature = 25;

  final List<Molecule> molecules = [];
  Timer? timer;

  String? reactionEquation;
  Timer? equationTimer;

  Size? screenSize;

  @override
  void initState() {
    super.initState();
    _initMolecules();
    _startEngine();
  }

  // ----------------------------
  // INIT MOLECULES حسب التفاعل
  // ----------------------------
  void _initMolecules() {
    molecules.clear();

    if (selectedReaction == ReactionType.ammoniaSalt) {
      molecules.addAll([
        Molecule.cluster(
          "HCl",
          [Atom("H", 1), Atom("Cl", -1)],
          Colors.green,
          const Offset(80, 320),
        ),
        Molecule.cluster(
          "NH3",
          [Atom("N", 0), Atom("H", 1), Atom("H", 1), Atom("H", 1)],
          Colors.indigo,
          const Offset(220, 320),
        ),
      ]);
    }

    if (selectedReaction == ReactionType.acidWater) {
      molecules.addAll([
        Molecule.cluster(
          "HNO3",
          [
            Atom("H", 1),
            Atom("N", 0),
            Atom("O", -1),
            Atom("O", -1),
            Atom("O", -1),
          ],
          Colors.redAccent,
          const Offset(80, 120),
        ),
        Molecule.cluster(
          "H2O",
          [
            Atom("H", 1),
            Atom("H", 1),
            Atom("O", -2),
          ],
          Colors.blueAccent,
          const Offset(220, 120),
        ),
      ]);
    }
  }

  // ----------------------------
  // ENGINE
  // ----------------------------
  void _startEngine() {
    timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted) return;

      setState(() {
        _applyPhysics();
        _handleCollisions();
        _applyBounds();
        _handleReactionState();
      });
    });
  }

  void _applyPhysics() {
    for (var m in molecules) {
      m.updateMotion(temperature);
    }
  }

  void _applyBounds() {
    if (screenSize == null) return;

    for (var m in molecules) {
      if (m.position.dx < 0 || m.position.dx > screenSize!.width - 60) {
        m.velocity = Offset(-m.velocity.dx * 0.8, m.velocity.dy);
      }

      if (m.position.dy < 0 || m.position.dy > screenSize!.height - 200) {
        m.velocity = Offset(m.velocity.dx, -m.velocity.dy * 0.8);
      }
    }
  }

  void _handleCollisions() {
    for (int i = 0; i < molecules.length; i++) {
      for (int j = i + 1; j < molecules.length; j++) {
        final a = molecules[i];
        final b = molecules[j];

        if ((a.position - b.position).distance < 70) {
          if (state == ReactionState.forward) {
            _triggerReaction(a, b);
          } else if (state == ReactionState.reverse) {
            a.separateFrom(b);
          }
        }
      }
    }
  }

  void _handleReactionState() {
    if (temperature > 70) {
      state = ReactionState.reverse;
    }
  }

  // ----------------------------
  // REACTIONS ENGINE
  // ----------------------------
  void _triggerReaction(Molecule a, Molecule b) {
    // NH3 + HCl
    if (selectedReaction == ReactionType.ammoniaSalt) {
      if ((a.name == "HCl" && b.name == "NH3") ||
          (a.name == "NH3" && b.name == "HCl")) {

        molecules.remove(a);
        molecules.remove(b);

        molecules.add(
          Molecule.cluster(
            "NH4+ Cl-",
            [
              Atom("N", 0),
              Atom("H", 1),
              Atom("H", 1),
              Atom("H", 1),
              Atom("H", 1),
              Atom("Cl", -1),
            ],
            Colors.purple,
            (a.position + b.position) / 2,
          ),
        );

        _showEquation("HCl + NH3 → NH4⁺ + Cl⁻");
      }
    }

    // HNO3 + H2O
    if (selectedReaction == ReactionType.acidWater) {
      if ((a.name == "HNO3" && b.name == "H2O") ||
          (a.name == "H2O" && b.name == "HNO3")) {

        molecules.remove(a);
        molecules.remove(b);

        molecules.add(
          Molecule.cluster(
            "H3O+ NO3-",
            [
              Atom("H", 1),
              Atom("H", 1),
              Atom("H", 1),
              Atom("O", -2),
              Atom("N", 0),
              Atom("O", -1),
              Atom("O", -1),
              Atom("O", -1),
            ],
            Colors.orange,
            (a.position + b.position) / 2,
          ),
        );

        _showEquation("HNO3 + H2O → H3O⁺ + NO3⁻");
      }
    }
  }

  // ----------------------------
  // EQUATION DISPLAY
  // ----------------------------
  void _showEquation(String text) {
    setState(() {
      reactionEquation = text;
    });

    equationTimer?.cancel();
    equationTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        reactionEquation = null;
      });
    });
  }

  // ----------------------------
  // UI ACTIONS
  // ----------------------------
  void startReaction() {
    setState(() {
      state = ReactionState.forward;
      for (var m in molecules) {
        m.activate();
      }
    });
  }

  void heat() {
    setState(() {
      temperature = (temperature + 10).clamp(0, 100);
    });
  }

  void resetSimulation() {
    setState(() {
      state = ReactionState.idle;
      reactionEquation = null;
      _initMolecules();
    });
  }

  // ----------------------------
  // BUILD
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Advanced Chemical Lab")),

      body: Column(
        children: [

          // EQUATION DISPLAY
          if (reactionEquation != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                reactionEquation!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // REACTION SELECTOR
          DropdownButton<ReactionType>(
            value: selectedReaction,
            dropdownColor: Colors.black,
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedReaction = value;
                resetSimulation();
              });
            },
            items: const [
              DropdownMenuItem(
                value: ReactionType.ammoniaSalt,
                child: Text("NH3 + HCl → Salt Formation"),
              ),
              DropdownMenuItem(
                value: ReactionType.acidWater,
                child: Text("Acid + Water Ionization"),
              ),
            ],
          ),

          Expanded(
            child: Stack(
              children: molecules.map((e) => e.build()).toList(),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: startReaction, child: const Text("Start")),
              ElevatedButton(onPressed: heat, child: const Text("Heat")),
              ElevatedButton(onPressed: resetSimulation, child: const Text("Reset")),
            ],
          ),

          Slider(
            value: temperature,
            min: 0,
            max: 100,
            onChanged: (v) => setState(() => temperature = v),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    equationTimer?.cancel();
    super.dispose();
  }
}

// ============================
// MOLECULE + ATOM MODEL
// ============================

class Molecule {
  final String name;
  final List<Atom> atoms;
  final Color color;
  Offset position;

  Offset velocity = Offset.zero;
  bool active = false;

  late final List<Offset> atomOffsets;

  Molecule.cluster(this.name, this.atoms, this.color, this.position) {
    atomOffsets = List.generate(atoms.length, (i) {
      final angle = (2 * pi * i) / atoms.length;
      return Offset(cos(angle) * 14, sin(angle) * 14);
    });
  }

  void activate() {
    active = true;
    velocity = Offset(
      Random().nextDouble() * 4 - 2,
      Random().nextDouble() * 4 - 2,
    );
  }

  void updateMotion(double temp) {
    if (!active) return;

    final factor = 1 + temp / 5000;
    velocity *= factor;
    position += velocity;
  }

  void separateFrom(Molecule other) {
    final dir = (other.position - position);
    position -= dir * 0.02;
    other.position += dir * 0.02;

    velocity += Offset(Random().nextDouble() - 0.5, Random().nextDouble() - 0.5);
    other.velocity += Offset(Random().nextDouble() - 0.5, Random().nextDouble() - 0.5);
  }

  Widget build() {
    return Stack(
      children: List.generate(atoms.length, (i) {
        final atom = atoms[i];

        return Positioned(
          left: position.dx + atomOffsets[i].dx,
          top: position.dy + atomOffsets[i].dy,
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _color(atom.symbol),
                  boxShadow: [
                    BoxShadow(
                      color: _color(atom.symbol).withOpacity(0.5),
                      blurRadius: 8,
                    )
                  ],
                ),
              ),

              if (atom.charge != 0)
                Text(
                  atom.charge > 0 ? "+${atom.charge}" : "${atom.charge}",
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                )
            ],
          ),
        );
      }),
    );
  }

  Color _color(String a) {
    switch (a) {
      case "H":
        return Colors.white;
      case "O":
        return Colors.red;
      case "N":
        return Colors.blue;
      case "Cl":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class Atom {
  final String symbol;
  final int charge;

  Atom(this.symbol, this.charge);
}
