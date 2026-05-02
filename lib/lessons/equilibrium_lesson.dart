import 'dart:math';
import 'package:flutter/material.dart';
import '../constants.dart';

class EquilibriumScreen extends StatefulWidget {
  const EquilibriumScreen({super.key});

  @override
  State<EquilibriumScreen> createState() => _EquilibriumScreenState();
}

class _EquilibriumScreenState extends State<EquilibriumScreen>
    with SingleTickerProviderStateMixin, TickerProviderStateMixin {
  late AnimationController controller;
  late TabController tabController;

  final Random random = Random();

  // =====================
  // 🧪 النظام الكيميائي
  // =====================
  int n2 = 10;
  int h2 = 30;
  int nh3 = 5;

  double pressure = 1;
  double temperature = 25;

  ReactionDirection direction = ReactionDirection.equilibrium;

  final List<Molecule> molecules = [];
  final List<Electron> electrons = [];

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 2, vsync: this);

    // molecules
    for (int i = 0; i < 8; i++) {
      molecules.add(Molecule("N₂", Colors.blue));
      molecules.add(Molecule("H₂", Colors.grey));
      molecules.add(Molecule("NH₃", Colors.green));
    }

    // electrons
    for (int i = 0; i < 35; i++) {
      electrons.add(Electron(ElectronState.stable));
    }

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )
      ..addListener(_tick)
      ..repeat();
  }

  // =====================
  // 🔁 التحديث الرئيسي
  // =====================
  void _tick() {
    _calculateDirection();

    for (var e in electrons) {
      e.update(direction);
    }

    setState(() {});
  }

  // =====================
  // ⚖️ منطق الاتزان
  // =====================
  void _calculateDirection() {
    double forwardPower = (pressure * n2 + h2) * 0.8;
    double reversePower = (temperature * nh3) * 0.9;

    if (forwardPower > reversePower + 15) {
      direction = ReactionDirection.forward;
    } else if (reversePower > forwardPower + 15) {
      direction = ReactionDirection.reverse;
    } else {
      direction = ReactionDirection.equilibrium;
    }
  }

  // =====================
  // ⚙️ التحكم الكامل
  // =====================
  void addN2() => setState(() => n2++);
  void addH2() => setState(() => h2 += 3);

  void pUp() => setState(() => pressure += 5);
  void pDown() => setState(() => pressure = max(1, pressure - 5));

  void tUp() => setState(() => temperature += 5);
  void tDown() => setState(() => temperature = max(0, temperature - 5));

  // =====================
  // 🧱 UI
  // =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("التوازن الكيميائي"),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          TabBar(
            controller: tabController,
            tabs: const [
              Tab(text: "⚗️ المفاعل"),
              Tab(text: "⚖️ الميزان"),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _reactorTab(),
                _balanceTab(),
              ],
            ),
          ),

          _controls(),
        ],
      ),
    );
  }

  // =====================
  // ⚗️ المفاعل
  // =====================
  Widget _reactorTab() {
    return LayoutBuilder(
      builder: (context, c) {
        for (var m in molecules) {
          m.setBounds(c.maxWidth, c.maxHeight);
          m.move(temperature);
        }

        return Stack(
          children: [
            // electrons
            ...electrons.map((e) => Positioned(
                  left: e.x,
                  top: e.y,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: e.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: e.color.withOpacity(0.6),
                          blurRadius: 6,
                        )
                      ],
                    ),
                  ),
                )),

            // molecules
            ...molecules.map((m) => Positioned(
                  left: m.x,
                  top: m.y,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: m.color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(m.type[0],
                          style: const TextStyle(fontSize: 8)),
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  // =====================
  // ⚖️ الميزان (Sphere System)
  // =====================
  Widget _balanceTab() {
    double left = n2 + h2 + pressure * 0.2;
    double right = nh3 * 2 + temperature * 0.1;
    double tilt = right - left;

    String status;
    if (tilt.abs() < 3) {
      status = "⚖️ اتزان ديناميكي";
    } else {
      status = tilt > 0 ? "➡️ نحو NH₃" : "⬅️ نحو المتفاعلات";
    }

    return Column(
      children: [
        const SizedBox(height: 10),

        Text(
          status,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),

        const SizedBox(height: 30),

        Expanded(
          child: Center(
            child: Transform.rotate(
              angle: tilt * 0.03,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 260,
                    height: 10,
                    color: Colors.brown,
                  ),
                  Container(
                    width: 10,
                    height: 120,
                    color: Colors.grey,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _pan(left, Colors.blue),
                      _pan(right, Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            "☁️ السحاب + الضغط + الحرارة يؤثرون على الميزان (Sphere Logic)",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _pan(double w, Color c) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: c.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: c),
          ),
          child: Center(
            child: Text(
              w.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // =====================
  // ⚙️ التحكم الكامل (بدون حذف أي فكرة)
  // =====================
  Widget _controls() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black26,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: addN2, child: const Text("N₂ +")),
              ElevatedButton(onPressed: addH2, child: const Text("H₂ +")),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: pUp, child: const Text("P +")),
              ElevatedButton(onPressed: pDown, child: const Text("P -")),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: tUp, child: const Text("T +")),
              ElevatedButton(onPressed: tDown, child: const Text("T -")),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    tabController.dispose();
    super.dispose();
  }
}

// =====================
// MODELS
// =====================

enum ReactionDirection { forward, reverse, equilibrium }

enum ElectronState { stable, unstable }

class Molecule {
  String type;
  Color color;

  double x = 0, y = 0;
  double vx = 0, vy = 0;

  double w = 300, h = 500;

  Molecule(this.type, this.color) {
    final r = Random();
    vx = (r.nextDouble() - 0.5) * 3;
    vy = (r.nextDouble() - 0.5) * 3;
  }

  void setBounds(double width, double height) {
    w = width;
    h = height;
  }

  void move(double temp) {
    double speed = 0.5 + (temp / 60);

    x += vx * speed;
    y += vy * speed;

    if (x < 0 || x > w) vx = -vx;
    if (y < 0 || y > h) vy = -vy;

    x = x.clamp(0, w);
    y = y.clamp(0, h);
  }
}

class Electron {
  double x = 0, y = 0;
  double vx = 0, vy = 0;

  ElectronState state;

  Electron(this.state) {
    final r = Random();
    x = r.nextDouble() * 300;
    y = r.nextDouble() * 500;
  }

  void update(ReactionDirection dir) {
    if (dir == ReactionDirection.forward) {
      state = ElectronState.stable;
      vx = 2;
      vy = 0;
    } else if (dir == ReactionDirection.reverse) {
      state = ElectronState.unstable;
      vx = Random().nextDouble() * 6 - 3;
      vy = Random().nextDouble() * 6 - 3;
    } else {
      vx *= 0.9;
      vy *= 0.9;
    }

    x += vx;
    y += vy;
  }

  Color get color =>
      state == ElectronState.stable ? Colors.blueAccent : Colors.redAccent;
}
