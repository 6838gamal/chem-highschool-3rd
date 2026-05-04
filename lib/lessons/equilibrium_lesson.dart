import 'dart:math';
import 'package:flutter/material.dart';

class EquilibriumScreen extends StatefulWidget {
  const EquilibriumScreen({Key? key}) : super(key: key);

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

    // 🧪 إنشاء الجزيئات (نظام البداية)
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
      m.update(heatOn, pressure, direction, boxSize);
    }

    setState(() {});
  }

  // ⚖️ حساب اتجاه التفاعل
  void _calculateDirection() {
    int reactants = molecules
        .where((m) =>
            m.type == MoleculeType.N2 || m.type == MoleculeType.H2)
        .length;

    int products =
        molecules.where((m) => m.type == MoleculeType.NH3).length;

    double diff = (products - reactants).toDouble();

    if (diff > 2) {
      direction = ReactionDirection.reverse;
    } else if (diff < -2) {
      direction = ReactionDirection.forward;
    } else {
      direction = ReactionDirection.equilibrium;
    }
  }

  // 🔥 التحكم بالحرارة
  void toggleHeat() => setState(() => heatOn = !heatOn);

  // ضغط
  void increaseP() =>
      setState(() => pressure = (pressure + 0.2).clamp(0.5, 3));

  void decreaseP() =>
      setState(() => pressure = (pressure - 0.2).clamp(0.5, 3));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Column(
        children: [

          const SizedBox(height: 40),

          // 🔘 التابات
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tab("المفاعل", 0),
              _tab("التحليل", 1),
            ],
          ),

          Expanded(
            child: tab == 0 ? _reactorTab() : _analysisTab(),
          ),
        ],
      ),
    );
  }

  // =========================
  // 🟢 TAB 1: Reactor (رجوع كامل)
  // =========================
  Widget _reactorTab() {
    return LayoutBuilder(
      builder: (context, constraints) {

        boxSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return Stack(
          children: molecules.map((m) {
            return Positioned(
              left: m.x,
              top: m.y,
              child: Column(
                children: [

                  // الذرات
                  Row(children: m.buildAtoms()),

                  // اسم الجزيء
                  Text(
                    m.label(),
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // =========================
  // 🔵 TAB 2: Analysis (ميزان + سحاب + أرقام)
  // =========================
  Widget _analysisTab() {

    int reactants =
        molecules.where((m) => m.type != MoleculeType.NH3).length;

    int products =
        molecules.where((m) => m.type == MoleculeType.NH3).length;

    double diff = (products - reactants).toDouble();

    double balanceAngle =
        (diff * pressure * (heatOn ? 0.3 : 0.2))
            .clamp(-0.6, 0.6);

    return Column(
      children: [

        const SizedBox(height: 20),

        // ⚖️ الميزان
        Transform.rotate(
          angle: balanceAngle,
          child: Container(
            width: 220,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.brown,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          "Reactants: $reactants | Products: $products",
          style: const TextStyle(color: Colors.white),
        ),

        Text(
          "Pressure: ${pressure.toStringAsFixed(1)}",
          style: const TextStyle(color: Colors.white70),
        ),

        const SizedBox(height: 10),

        // ☁️ السحاب (مرتبط بالضغط)
        Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.transparent,
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ⚙️ التحكم
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
              "P ${pressure.toStringAsFixed(1)}",
              style: const TextStyle(color: Colors.white),
            ),

            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: increaseP,
            ),
          ],
        ),
      ],
    );
  }

  Widget _tab(String title, int i) {
    return TextButton(
      onPressed: () => setState(() => tab = i),
      child: Text(
        title,
        style: TextStyle(
          color: tab == i ? Colors.orange : Colors.white,
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
// ENUMS
// =========================

enum ReactionDirection { forward, reverse, equilibrium }

enum MoleculeType { N2, H2, NH3 }

// =========================
// MOLECULE ENGINE (كما هو بدون حذف)
// =========================

class Molecule {
  MoleculeType type;

  double x = Random().nextDouble() * 200;
  double y = Random().nextDouble() * 300;

  double t = 0;

  Molecule({required this.type});

  void update(bool heat, double pressure,
      ReactionDirection direction, Size? box) {

    double speed = heat ? 0.06 : 0.03;

    if (direction == ReactionDirection.forward) x += speed * 10;
    if (direction == ReactionDirection.reverse) x -= speed * 10;

    t += speed;
    y += sin(t) * 1.5;

    if (box != null) {
      x = x.clamp(0, box.width - 30);
      y = y.clamp(0, box.height - 30);
    }

    if (Random().nextDouble() < 0.01 * pressure) {
      type = type == MoleculeType.NH3
          ? (Random().nextBool()
              ? MoleculeType.N2
              : MoleculeType.H2)
          : MoleculeType.NH3;
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
        ];
    }
  }

  Widget _atom(Color c) {
    return Container(
      margin: const EdgeInsets.all(2),
      width: 10,
      height: 10,
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
