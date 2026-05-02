import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants.dart';

// ================= Electron Model =================
class Electron {
  Offset pos;
  Offset target;

  Electron(this.pos, this.target);
}

// ================= Bond Type =================
enum BondType { ionic, covalent }

// ================= MAIN CLASS (مهم جدًا: لم يتم تغييره) =================
class SaltLabAllInOne extends StatefulWidget {
  const SaltLabAllInOne({super.key});

  @override
  State<SaltLabAllInOne> createState() => _SaltLabAllInOneState();
}

class _SaltLabAllInOneState extends State<SaltLabAllInOne>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final math.Random r = math.Random();

  // ================= Reaction =================
  BondType bondType = BondType.ionic;

  bool running = false;
  bool finished = false;

  Offset leftAtom = const Offset(80, 200);
  Offset rightAtom = const Offset(260, 200);

  late Electron electron;

  double angle = 0;

  // ================= pH =================
  int hCount = 10;
  int ohCount = 10;

  // ================= Salts =================
  final salts = {
    "NaCl": ["Na⁺", "Cl⁻"],
    "CaCl₂": ["Ca²⁺", "2Cl⁻"],
    "NH₄Cl": ["NH₄⁺", "Cl⁻"],
    "NaCN": ["Na⁺", "CN⁻"],
  };

  String selectedSalt = "NaCl";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    electron = Electron(leftAtom, rightAtom);
  }

  // ================= Electron Transfer =================
  void _updateReaction() {
    if (!running) return;

    setState(() {
      if (bondType == BondType.ionic) {
        Offset dir = electron.target - electron.pos;

        if (dir.distance < 2) {
          finished = true;
        } else {
          electron.pos += dir * 0.05;
        }
      } else {
        angle += 0.05;
      }
    });
  }

  void _startReaction() {
    setState(() {
      running = true;
      finished = false;
      electron.pos = leftAtom;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));
      _updateReaction();
      return running;
    });
  }

  // ================= pH Calculation (حقيقي لوغاريتمي) =================
  double _calculatePH() {
    double h = (hCount + 1) / 50;
    double oh = (ohCount + 1) / 50;

    if (hCount > ohCount) {
      return -math.log(h) / math.ln10;
    } else {
      double pOH = -math.log(oh) / math.ln10;
      return 14 - pOH;
    }
  }

  void _neutralize() {
    int reaction = math.min(hCount, ohCount);

    setState(() {
      hCount -= reaction;
      ohCount -= reaction;
    });
  }

  Color _getPHColor(double pH) {
    if (pH < 7) {
      return Color.lerp(Colors.red, Colors.green, pH / 7)!;
    } else {
      return Color.lerp(Colors.green, Colors.blue, (pH - 7) / 7)!;
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("مختبر الأملاح والتفاعلات"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "التفاعل"),
            Tab(text: "pH"),
            Tab(text: "الأملاح"),
            Tab(text: "التوصيل"),
            Tab(text: "أخرى"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _tabReaction(),
          _tabPH(),
          _tabSalts(),
          _simpleTab("التوصيل"),
          _simpleTab("قريباً"),
        ],
      ),
    );
  }

  // ================= Reaction Tab =================
  Widget _tabReaction() {
    return Column(
      children: [
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text("Ionic"),
              selected: bondType == BondType.ionic,
              onSelected: (_) =>
                  setState(() => bondType = BondType.ionic),
            ),
            const SizedBox(width: 10),
            ChoiceChip(
              label: const Text("Covalent"),
              selected: bondType == BondType.covalent,
              onSelected: (_) =>
                  setState(() => bondType = BondType.covalent),
            ),
          ],
        ),

        ElevatedButton(
          onPressed: _startReaction,
          child: const Text("بدء التفاعل"),
        ),

        Expanded(
          child: Stack(
            children: [
              // ===== Left Atom =====
              Positioned(
                left: leftAtom.dx,
                top: leftAtom.dy,
                child: _atom(
                    bondType == BondType.ionic
                        ? (finished ? "Na⁺" : "Na")
                        : "H",
                    Colors.grey),
              ),

              // ===== Right Atom =====
              Positioned(
                left: rightAtom.dx,
                top: rightAtom.dy,
                child: _atom(
                    bondType == BondType.ionic
                        ? (finished ? "Cl⁻" : "Cl")
                        : "H",
                    Colors.grey),
              ),

              // ===== Ionic Electron =====
              if (bondType == BondType.ionic &&
                  running &&
                  !finished)
                Positioned(
                  left: electron.pos.dx,
                  top: electron.pos.dy,
                  child: const Icon(Icons.circle,
                      size: 10, color: Colors.cyan),
                ),

              // ===== Covalent electrons =====
              if (bondType == BondType.covalent)
                ...List.generate(2, (i) {
                  double x =
                      170 + 30 * math.cos(angle + i * math.pi);
                  double y =
                      220 + 30 * math.sin(angle + i * math.pi);

                  return Positioned(
                    left: x,
                    top: y,
                    child: const Icon(Icons.circle,
                        size: 10, color: Colors.green),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _atom(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(label,
            style: const TextStyle(color: Colors.white))
      ],
    );
  }

  // ================= pH Tab =================
  Widget _tabPH() {
    double pH = _calculatePH().clamp(0, 14);
    Color color = _getPHColor(pH);

    return Column(
      children: [
        const SizedBox(height: 10),

        Slider(
          value: hCount.toDouble(),
          min: 0,
          max: 50,
          onChanged: (v) => setState(() => hCount = v.toInt()),
        ),

        Slider(
          value: ohCount.toDouble(),
          min: 0,
          max: 50,
          onChanged: (v) => setState(() => ohCount = v.toInt()),
        ),

        Text(
          "pH = ${pH.toStringAsFixed(2)}",
          style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold),
        ),

        ElevatedButton(
          onPressed: _neutralize,
          child: const Text("تعادل"),
        ),

        Expanded(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        )
      ],
    );
  }

  // ================= Salts Tab =================
  Widget _tabSalts() {
    return ListView(
      children: salts.entries.map((e) {
        return ListTile(
          title: Text(e.key,
              style: const TextStyle(color: Colors.white)),
          subtitle: Wrap(
            children: e.value
                .map((i) => Chip(
                      label: Text(i),
                      backgroundColor:
                          i.contains("⁺")
                              ? Colors.blue
                              : Colors.red,
                    ))
                .toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _simpleTab(String title) {
    return Center(
      child: Text(title,
          style: const TextStyle(color: Colors.white)),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
