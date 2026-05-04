import 'dart:math';
import 'package:flutter/material.dart';

class EquilibriumScreen extends StatefulWidget {
  const EquilibriumScreen({super.key});

  @override
  State<EquilibriumScreen> createState() => _EquilibriumScreenState();
}

class _EquilibriumScreenState extends State<EquilibriumScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;

  bool heatOn = false;
  double pressure = 1.0;

  final List<Molecule> molecules = [];

  ReactionDirection direction = ReactionDirection.equilibrium;

  Size? boxSize;

  @override
  void initState() {
    super.initState();

    // 🧪 إنشاء النظام
    for (int i = 0; i < 6; i++) {
      molecules.add(Molecule(type: MoleculeType.N2));
      molecules.add(Molecule(type: MoleculeType.H2));
    }

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )
      ..addListener(_tick)
      ..repeat();
  }

  void _tick() {
    _calculateDirection();

    for (var m in molecules) {
      m.update(heatOn, pressure, boxSize);
    }

    setState(() {});
  }

  // =========================
  // ⚖️ الاتزان
  // =========================
  void _calculateDirection() {
    int reactants = molecules
        .where((m) => m.type == MoleculeType.N2 || m.type == MoleculeType.H2)
        .length;

    int products =
        molecules.where((m) => m.type == MoleculeType.NH3).length;

    if (reactants > products + 2) {
      direction = ReactionDirection.forward;
    } else if (products > reactants + 2) {
      direction = ReactionDirection.reverse;
    } else {
      direction = ReactionDirection.equilibrium;
    }
  }

  void toggleHeat() => setState(() => heatOn = !heatOn);

  void addN2() => setState(() => molecules.add(Molecule(type: MoleculeType.N2)));
  void addH2() => setState(() => molecules.add(Molecule(type: MoleculeType.H2)));

  void increaseP() => setState(() => pressure = (pressure + 0.2).clamp(0.5, 3));
  void decreaseP() => setState(() => pressure = (pressure - 0.2).clamp(0.5, 3));

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: LayoutBuilder(
        builder: (context, constraints) {

          boxSize = Size(
            constraints.maxWidth,
            constraints.maxHeight * 0.45,
          );

          return Column(
            children: [

              const SizedBox(height: 45),

              const Text(
                "N₂ + 3H₂ ⇌ 2NH₃",
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),

              const SizedBox(height: 10),

              // 🧪 المفاعل
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: molecules.map((m) {
                      return Positioned(
                        left: m.x,
                        top: m.y,
                        child: Column(
                          children: [
                            Row(children: m.buildAtoms()),
                            Text(
                              m.label(),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                _status(),
                style: const TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 10),

              // 🎛️ التحكم
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  IconButton(
                    icon: Icon(
                      Icons.local_fire_department,
                      color: heatOn ? Colors.orange : Colors.grey,
                    ),
                    onPressed: toggleHeat,
                  ),

                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white),
                    onPressed: decreaseP,
                  ),

                  Text(
                    "P:${pressure.toStringAsFixed(1)}",
                    style: const TextStyle(color: Colors.white),
                  ),

                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: increaseP,
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: addN2, child: const Text("N₂")),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: addH2, child: const Text("H₂")),
                ],
              ),

              const SizedBox(height: 10),

              // ⚖️ الميزان
              _balance(),

              const SizedBox(height: 6),

              // ☁️ السحاب
              _cloud(),

              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }

  // =========================
  // ⚖️ الميزان (مصَحح بالكامل)
  // =========================
  Widget _balance() {
    int reactants =
        molecules.where((m) => m.type != MoleculeType.NH3).length;

    int products =
        molecules.where((m) => m.type == MoleculeType.NH3).length;

    // ✅ FIX: int → double
    double diff = (products - reactants).toDouble();

    double factor = (pressure * 0.25) + (heatOn ? 0.4 : 0.2);
    double angle = (diff * factor * 0.04).clamp(-0.6, 0.6);

    return Column(
      children: [

        const Text(
          "⚖️ الميزان الكيميائي",
          style: TextStyle(color: Colors.white),
        ),

        const SizedBox(height: 10),

        AnimatedRotation(
          turns: angle,
          duration: const Duration(milliseconds: 400),
          child: Container(
            width: 240,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.brown,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          diff.abs() < 2
              ? "اتزان"
              : diff > 0
                  ? "النواتج أثقل"
                  : "المتفاعلات أثقل",
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  // ☁️ السحاب تحت الميزان
  Widget _cloud() {
    return SizedBox(
      height: 30,
      child: Opacity(
        opacity: (pressure / 3).clamp(0.2, 0.7),
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.white24,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _status() {
    switch (direction) {
      case ReactionDirection.forward:
        return "تكوين NH₃";
      case ReactionDirection.reverse:
        return "تفكك NH₃";
      case ReactionDirection.equilibrium:
        return "اتزان ديناميكي";
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// =========================

enum ReactionDirection { forward, reverse, equilibrium }

enum MoleculeType { N2, H2, NH3 }

class Molecule {
  MoleculeType type;

  double x = Random().nextDouble() * 300;
  double y = Random().nextDouble() * 400;

  double t = 0;

  Molecule({required this.type});

  void update(bool heat, double pressure, Size? box) {
    double speed = heat ? 0.06 : 0.02;

    t += speed;

    x += sin(t) * (heat ? 1.2 : 0.5);
    y += cos(t) * (heat ? 1.2 : 0.5);

    // منع الخروج من الوعاء
    if (box != null) {
      x = x.clamp(0, box.width - 40);
      y = y.clamp(0, box.height - 40);
    }

    _reactionChance(heat);
  }

  void _reactionChance(bool heat) {
    double p = heat ? 0.02 : 0.008;

    if (Random().nextDouble() < p) {
      if (type == MoleculeType.N2 || type == MoleculeType.H2) {
        type = MoleculeType.NH3;
      } else {
        type = Random().nextBool()
            ? MoleculeType.N2
            : MoleculeType.H2;
      }
    }
  }

  List<Widget> buildAtoms() {
    switch (type) {
      case MoleculeType.N2:
        return [_atom(Colors.blue), _atom(Colors.blue)];
      case MoleculeType.H2:
        return [_atom(Colors.grey), _atom(Colors.grey)];
      case MoleculeType.NH3:
        return [
          _atom(Colors.blue),
          _atom(Colors.white),
          _atom(Colors.white),
          _atom(Colors.white),
        ];
    }
  }

  Widget _atom(Color c) {
    return Container(
      margin: const EdgeInsets.all(2),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.withOpacity(0.85),
      ),
    );
  }

  String label() {
    switch (type) {
      case MoleculeType.N2:
        return "N₂";
      case MoleculeType.H2:
        return "H₂";
      case MoleculeType.NH3:
        return "NH₃";
    }
  }
}
