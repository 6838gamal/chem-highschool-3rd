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

  int tab = 0;

  bool heatOn = false;
  double pressure = 1.0;

  final List<Molecule> molecules = [];

  ReactionDirection direction = ReactionDirection.equilibrium;

  Size? boxSize;

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 6; i++) {
      molecules.add(Molecule(type: MoleculeType.N2, side: Side.left));
      molecules.add(Molecule(type: MoleculeType.H2, side: Side.left));
    }

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_tick)..repeat();
  }

  void _tick() {
    _calculateDirection();

    for (var m in molecules) {
      m.update(heatOn, pressure, direction, boxSize);
    }

    setState(() {});
  }

  void _calculateDirection() {
    int reactants = molecules.where((m) =>
        m.type == MoleculeType.N2 || m.type == MoleculeType.H2).length;

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

  void increaseP() => setState(() => pressure = (pressure + 0.2).clamp(0.5, 3));
  void decreaseP() => setState(() => pressure = (pressure - 0.2).clamp(0.5, 3));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Column(
        children: [

          const SizedBox(height: 40),

          // 🔘 Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tabButton("المفاعل", 0),
              _tabButton("التحليل", 1),
            ],
          ),

          const SizedBox(height: 10),

          Expanded(
            child: tab == 0 ? _reactorTab() : _analysisTab(),
          ),
        ],
      ),
    );
  }

  // =========================
  // 🟢 TAB 1: المفاعل
  // =========================
  Widget _reactorTab() {
    return LayoutBuilder(
      builder: (context, constraints) {

        boxSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Container(
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
                child: Row(
                  children: [
                    Row(children: m.buildAtoms()),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // =========================
  // 🔵 TAB 2: التحليل
  // =========================
  Widget _analysisTab() {
    int reactants =
        molecules.where((m) => m.type != MoleculeType.NH3).length;

    int products =
        molecules.where((m) => m.type == MoleculeType.NH3).length;

    double balance = products - reactants;

    return Column(
      children: [

        const SizedBox(height: 10),

        // ⚖️ الميزان
        AnimatedRotation(
          turns: (balance * 0.03).clamp(-0.5, 0.5),
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: 240,
            height: 8,
            color: Colors.brown,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          "Reactants: $reactants | Products: $products",
          style: const TextStyle(color: Colors.white),
        ),

        Text(
          "Pressure: ${pressure.toStringAsFixed(1)}",
          style: const TextStyle(color: Colors.white70),
        ),

        const SizedBox(height: 10),

        // ☁️ السحاب
        Opacity(
          opacity: (pressure / 3).clamp(0.2, 0.7),
          child: Container(
            height: 40,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.white24, Colors.transparent],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 🧪 كروت الذرات فوق الميزان
        Wrap(
          spacing: 8,
          children: molecules.take(6).map((m) {
            return Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                m.label(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _tabButton(String title, int index) {
    return TextButton(
      onPressed: () => setState(() => tab = index),
      child: Text(
        title,
        style: TextStyle(
          color: tab == index ? Colors.orange : Colors.white,
        ),
      ),
    );
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

enum Side { left, right }

class Molecule {
  MoleculeType type;
  Side side;

  double x = Random().nextDouble() * 100;
  double y = Random().nextDouble() * 300;

  double t = 0;

  Molecule({required this.type, required this.side});

  void update(bool heat, double pressure,
      ReactionDirection direction, Size? box) {

    double speed = heat ? 0.08 : 0.04;

    // 🟢 TAB1: اتجاه الحركة
    if (direction == ReactionDirection.forward) {
      x += speed * 10; // left → right
    } else if (direction == ReactionDirection.reverse) {
      x -= speed * 10; // right → left
    }

    t += speed;
    y += sin(t) * 1.2;

    if (box != null) {
      x = x.clamp(0, box.width - 30);
      y = y.clamp(0, box.height - 30);
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
        color: c,
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
