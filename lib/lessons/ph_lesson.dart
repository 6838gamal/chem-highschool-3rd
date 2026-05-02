import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../constants.dart';

/// =========================
/// Molecular Reaction Simulation (Advanced Interaction)
/// - Collision-based bonding
/// - Inter-molecule interaction (merge + split)
/// - Reversible chemistry with temperature
/// =========================

enum ReactionState { idle, forward, reverse }

class HamoothWaAsasPage extends StatefulWidget {
  const HamoothWaAsasPage({super.key});

  @override
  State<HamoothWaAsasPage> createState() => _HamoothWaAsasPageState();
}

class _HamoothWaAsasPageState extends State<HamoothWaAsasPage> {
  final Random random = Random();

  ReactionState state = ReactionState.idle;
  double temperature = 25;

  final List<Molecule> molecules = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _initMolecules();
    _startEngine();
  }

  void _initMolecules() {
    molecules.clear();

    molecules.addAll([
      Molecule.cluster("HNO3", ["H", "N", "O", "O", "O"], Colors.redAccent, const Offset(80, 120)),
      Molecule.cluster("H2O", ["H", "H", "O"], Colors.blueAccent, const Offset(220, 120)),
      Molecule.cluster("HCl", ["H", "Cl"], Colors.green, const Offset(80, 320)),
      Molecule.cluster("NH3", ["N", "H", "H", "H"], Colors.indigo, const Offset(220, 320)),
    ]);
  }

  void _startEngine() {
    timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted) return;

      setState(() {
        _applyPhysics();
        _handleCollisions();
        _handleReactionState();
      });
    });
  }

  void _applyPhysics() {
    for (var m in molecules) {
      m.updateMotion(temperature);
    }
  }

  void _handleCollisions() {
    for (int i = 0; i < molecules.length; i++) {
      for (int j = i + 1; j < molecules.length; j++) {
        final a = molecules[i];
        final b = molecules[j];

        if ((a.position - b.position).distance < 80) {
          if (state == ReactionState.forward) {
            a.bindTo(b);
          } else if (state == ReactionState.reverse) {
            a.separateFrom(b);
          }
        }
      }
    }
  }

  void _handleReactionState() {
    if (temperature > 60) {
      state = ReactionState.reverse;
    }
  }

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
      temperature += 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Molecular Interaction Engine")),
      body: Column(
        children: [
          Expanded(
            child: Stack(children: molecules.map((e) => e.build()).toList()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: startReaction, child: const Text("Start")),
              ElevatedButton(onPressed: heat, child: const Text("Heat")),
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
    super.dispose();
  }
}

class Molecule {
  final String name;
  final List<String> atoms;
  final Color color;
  Offset position;

  Offset velocity = Offset.zero;
  bool active = false;

  Molecule.cluster(this.name, this.atoms, this.color, this.position);

  void activate() {
    active = true;
    velocity = Offset(
      Random().nextDouble() * 4 - 2,
      Random().nextDouble() * 4 - 2,
    );
  }

  void updateMotion(double temp) {
    if (!active) return;

    velocity *= 1 + temp / 3000;
    position += velocity;
  }

  void bindTo(Molecule other) {
    final dir = (other.position - position) * 0.02;
    position += dir;
    other.position -= dir;

    velocity *= 0.95;
    other.velocity *= 0.95;
  }

  void separateFrom(Molecule other) {
    final dir = (other.position - position);
    position -= dir * 0.01;
    other.position += dir * 0.01;

    velocity = Offset.zero;
    other.velocity = Offset.zero;
  }

  Widget build() {
    return Stack(
      children: atoms.map((a) {
        return Positioned(
          left: position.dx + Random().nextDouble() * 10,
          top: position.dy + Random().nextDouble() * 10,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color(a),
              boxShadow: [
                BoxShadow(
                  color: _color(a).withOpacity(0.6),
                  blurRadius: 10,
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _color(String a) {
    switch (a) {
      case "H": return Colors.white;
      case "O": return Colors.red;
      case "N": return Colors.blue;
      case "Cl": return Colors.green;
      default: return Colors.grey;
    }
  }
}
