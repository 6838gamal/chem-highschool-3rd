import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants.dart';

// ================= PARTICLE =================
class Particle {
  Offset pos;
  Offset vel;
  double charge;
  Color color;
  bool fixed;

  Particle({
    required this.pos,
    required this.vel,
    required this.charge,
    required this.color,
    this.fixed = false,
  });
}

// ================= TYPES =================
enum BondType { ionic, covalent }

// ================= MAIN CLASS =================
class SaltLabAllInOne extends StatefulWidget {
  const SaltLabAllInOne({super.key});

  @override
  State<SaltLabAllInOne> createState() => _SaltLabAllInOneState();
}

class _SaltLabAllInOneState extends State<SaltLabAllInOne>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ================= PHYSICS ENGINE =================
  List<Particle> particles = [];

  final double k = 0.8;
  final double damping = 0.97;
  final Offset gravity = Offset(0, 0.03);

  // ================= REACTION =================
  BondType bondType = BondType.ionic;
  String equation = "";
  bool running = false;

  // ================= pH =================
  int h = 10;
  int oh = 10;

  // ================= SALTS =================
  final List<Map<String, dynamic>> saltsInfo = [
    {
      "name": "NH₄Cl",
      "medium": "حمضي",
      "acid": "HCl (قوي)",
      "base": "NH₃ (ضعيف)",
      "effect": "يزيد H⁺ → يقل pH"
    },
    {
      "name": "CH₃COONa",
      "medium": "قاعدي",
      "acid": "CH₃COOH (ضعيف)",
      "base": "NaOH (قوي)",
      "effect": "يزيد OH⁻ → يرتفع pH"
    },
    {
      "name": "NaCl",
      "medium": "متعادل",
      "acid": "HCl (قوي)",
      "base": "NaOH (قوي)",
      "effect": "لا تغيير في pH"
    },
    {
      "name": "NaCN",
      "medium": "قاعدي",
      "acid": "HCN (ضعيف)",
      "base": "NaOH (قوي)",
      "effect": "قاعدي بسبب CN⁻"
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // ================= PH =================
  double _ph() {
    double hv = (h + 1) / 50;
    double ov = (oh + 1) / 50;

    if (h > oh) {
      return -math.log(hv) / math.ln10;
    } else {
      double poh = -math.log(ov) / math.ln10;
      return 14 - poh;
    }
  }

  Color _phColor(double pH) {
    if (pH < 7) return Colors.red;
    if (pH > 7) return Colors.blue;
    return Colors.green;
  }

  // ================= INIT PHYSICS =================
  void initPhysics() {
    particles = [
      Particle(
        pos: const Offset(100, 200),
        vel: Offset.zero,
        charge: 1,
        color: Colors.blue,
      ),
      Particle(
        pos: const Offset(260, 200),
        vel: Offset.zero,
        charge: -1,
        color: Colors.red,
      ),
      Particle(
        pos: const Offset(180, 240),
        vel: Offset.zero,
        charge: -0.5,
        color: Colors.cyan,
      ),
    ];
  }

  // ================= PHYSICS ENGINE =================
  void updatePhysics() {
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final a = particles[i];
        final b = particles[j];

        final dir = b.pos - a.pos;
        final dist = dir.distance + 0.1;

        final force = (k * a.charge * b.charge) / (dist * dist);
        final norm = Offset(dir.dx / dist, dir.dy / dist);

        if (!a.fixed) a.vel += norm * (-force);
        if (!b.fixed) b.vel += norm * (force);
      }
    }

    for (var p in particles) {
      if (!p.fixed) {
        p.vel += gravity;
        p.vel *= damping;
        p.pos += p.vel;
      }
    }
  }

  // ================= START =================
  void startSimulation() {
    setState(() {
      running = true;
      equation = bondType == BondType.ionic
          ? "Na + Cl → Na⁺ + Cl⁻"
          : "H + H → H₂";

      initPhysics();
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!running) return false;

      setState(() {
        updatePhysics();
      });

      return true;
    });
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("مختبر الكيمياء التفاعلي"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "التفاعل"),
            Tab(text: "الأملاح"),
            Tab(text: "المختبر"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _reactionTab(),
          _saltTab(),
          _labTab(),
        ],
      ),
    );
  }

  // ================= TAB 1 =================
  Widget _reactionTab() {
    return Column(
      children: [
        const SizedBox(height: 10),

        Text(
          equation,
          style: const TextStyle(color: Colors.white),
        ),

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
          onPressed: startSimulation,
          child: const Text("تشغيل التفاعل"),
        ),

        Expanded(
          child: Stack(
            children: particles.map((p) {
              return Positioned(
                left: p.pos.dx,
                top: p.pos.dy,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.color,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ================= TAB 2: SALTS =================
  Widget _saltTab() {
    return ListView.builder(
      itemCount: saltsInfo.length,
      itemBuilder: (context, i) {
        final s = saltsInfo[i];

        Color c;
        if (s["medium"] == "حمضي") {
          c = Colors.red;
        } else if (s["medium"] == "قاعدي") {
          c = Colors.blue;
        } else {
          c = Colors.green;
        }

        return Card(
          color: Colors.white10,
          child: ListTile(
            title: Text(
              s["name"],
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              "الوسط: ${s["medium"]}",
              style: TextStyle(color: c),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(s["name"]),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("الوسط: ${s["medium"]}"),
                      Text("الحمض: ${s["acid"]}"),
                      Text("القاعدة: ${s["base"]}"),
                      Text("التأثير: ${s["effect"]}"),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ================= TAB 3 =================
  Widget _labTab() {
    double pH = _ph();

    return Column(
      children: [
        const SizedBox(height: 10),

        Text(
          "pH = ${pH.toStringAsFixed(2)}",
          style: TextStyle(color: _phColor(pH), fontSize: 22),
        ),

        Slider(
          value: h.toDouble(),
          min: 0,
          max: 50,
          onChanged: (v) => setState(() => h = v.toInt()),
        ),

        Slider(
          value: oh.toDouble(),
          min: 0,
          max: 50,
          onChanged: (v) => setState(() => oh = v.toInt()),
        ),

        Expanded(
          child: Container(
            margin: const EdgeInsets.all(10),
            width: double.infinity,
            color: _phColor(pH).withOpacity(0.2),
            child: Stack(
              children: particles.map((p) {
                return Positioned(
                  left: p.pos.dx,
                  top: p.pos.dy,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
