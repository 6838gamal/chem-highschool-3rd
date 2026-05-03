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

  final List<Molecule> molecules = [];

  ReactionDirection direction = ReactionDirection.equilibrium;

  @override
  void initState() {
    super.initState();

    // 🧪 إنشاء النظام الجزيئي
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
      m.update(heatOn, molecules);
    }

    setState(() {});
  }

  // ==============================
  // ⚖️ الاتزان الحقيقي
  // ==============================
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

  void toggleHeat() {
    setState(() => heatOn = !heatOn);
  }

  // ==============================
  // UI
  // ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [

          const SizedBox(height: 45),

          // ⚗️ المعادلة
          const Text(
            "N₂ + 3H₂ ⇌ 2NH₃",
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),

          const SizedBox(height: 10),

          // =======================
          // 🧪 المفاعل الجزيئي
          // =======================
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
                  return Stack(
                    children: [
                      ...m.bonds.map((b) {
                        return Positioned(
                          left: b.x1,
                          top: b.y1,
                          child: Container(
                            width: b.length,
                            height: 2,
                            color: Colors.white30,
                          ),
                        );
                      }),

                      Positioned(
                        left: m.x,
                        top: m.y,
                        child: Row(
                          children: m.atoms
                              .map((a) => Container(
                                    margin: const EdgeInsets.all(2),
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: a.color,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 5),

          // 🧠 الحالة
          Text(
            _status(),
            style: const TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 10),

          // 🔥 الحرارة
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
              Text(
                heatOn ? "Heat ON" : "Heat OFF",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // =======================
          // ⚖️ الميزان
          // =======================
          _balance(),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ==============================
  // ⚖️ الميزان العلمي الصحيح
  // ==============================
  Widget _balance() {
    int reactants = molecules
        .where((m) => m.type != MoleculeType.NH3)
        .length;

    int products =
        molecules.where((m) => m.type == MoleculeType.NH3).length;

    double diff = (products - reactants).toDouble();

    double angle = diff * 0.04;
    angle = angle.clamp(-0.6, 0.6);

    return Column(
      children: [

        const Text(
          "⚖️ الميزان الكيميائي",
          style: TextStyle(color: Colors.white),
        ),

        const SizedBox(height: 10),

        Transform.rotate(
          angle: angle,
          child: Container(
            width: 220,
            height: 6,
            color: Colors.brown,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          diff.abs() < 2
              ? "اتزان"
              : diff > 0
                  ? "NH₃ أثقل"
                  : "المتفاعلات أثقل",
          style: const TextStyle(color: Colors.white70),
        ),

        const SizedBox(height: 10),

        // =======================
        // ☁️ pH SCALE
        // =======================
        Stack(
          children: [

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Positioned(
              left: _ph(),
              child: const Icon(Icons.arrow_drop_down, color: Colors.white),
            ),
          ],
        ),

        const SizedBox(height: 5),

        const Text(
          "0 = حمضي | 7 = متعادل | 14 = قاعدي",
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  double _ph() {
    double ph = 7 + (molecules.length / 10);
    ph = ph.clamp(0, 14);
    return (ph / 14) * 260;
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

// ==============================
enum ReactionDirection { forward, reverse, equilibrium }

enum MoleculeType { N2, H2, NH3 }

class Atom {
  Color color;
  Atom(this.color);
}

class Bond {
  double x1, y1, length;
  Bond(this.x1, this.y1, this.length);
}

class Molecule {
  MoleculeType type;

  double x = 0;
  double y = 0;

  double vx = 1.5;
  double vy = 1;

  List<Atom> atoms = [];
  List<Bond> bonds = [];

  Molecule({required this.type}) {
    final r = Random();

    x = r.nextDouble() * 100;
    y = r.nextDouble() * 300;

    _build();
  }

  void _build() {
    atoms.clear();
    bonds.clear();

    if (type == MoleculeType.N2) {
      atoms.add(Atom(Colors.blue));
      atoms.add(Atom(Colors.blue));
    }

    if (type == MoleculeType.H2) {
      atoms.add(Atom(Colors.grey));
      atoms.add(Atom(Colors.grey));
    }

    if (type == MoleculeType.NH3) {
      atoms.add(Atom(Colors.blue));
      atoms.add(Atom(Colors.white));
      atoms.add(Atom(Colors.white));
      atoms.add(Atom(Colors.white));
    }
  }

  void update(bool heat, List<Molecule> all) {
    double speed = heat ? 3 : 1.5;

    x += vx * speed;
    y += vy * speed;

    // تصادم بسيط
    for (var other in all) {
      if (other == this) continue;

      double dx = (x - other.x).abs();
      double dy = (y - other.y).abs();

      if (dx < 20 && dy < 20) {
        _react(other);
      }
    }
  }

  void _react(Molecule other) {
    if (type == MoleculeType.N2 && other.type == MoleculeType.H2) {
      type = MoleculeType.NH3;
      other.type = MoleculeType.NH3;
      _build();
      other._build();
    }

    if (type == MoleculeType.NH3 && other.type == MoleculeType.NH3) {
      type = MoleculeType.N2;
      other.type = MoleculeType.H2;
      _build();
      other._build();
    }
  }
}
