import 'package:flutter/material.dart';
import 'dart:math';

class BondingScreen extends StatefulWidget {
  const BondingScreen({super.key});

  @override
  State<BondingScreen> createState() => _BondingScreenState();
}

// ================= MODEL =================

class Nucleus {
  int protons;
  int neutrons;
  String symbol;

  Nucleus(this.protons, this.neutrons, this.symbol);

  int get mass => protons + neutrons;
}

enum ReactionType {
  alpha,
  betaMinus,
  betaPlus,
  electronCapture,
  neutronCapture,
  transmutation,
  fission,
  fusion,
}

// ================= STATE =================

class _BondingScreenState extends State<BondingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  int selected = 0;

  late List<Map<String, dynamic>> reactions;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    // 🔥 كل التفاعلات الثمانية
    reactions = [
      {"name": "β⁻ C → N", "type": ReactionType.betaMinus, "before": Nucleus(6, 8, "C"), "after": Nucleus(7, 7, "N")},
      {"name": "β⁺ C → B", "type": ReactionType.betaPlus, "before": Nucleus(6, 5, "C"), "after": Nucleus(5, 6, "B")},
      {"name": "Electron Capture Rb → Kr", "type": ReactionType.electronCapture, "before": Nucleus(37, 44, "Rb"), "after": Nucleus(36, 45, "Kr")},
      {"name": "Alpha Ra → Rn", "type": ReactionType.alpha, "before": Nucleus(88, 138, "Ra"), "after": Nucleus(86, 136, "Rn")},
      {"name": "Alpha Po → Pb", "type": ReactionType.alpha, "before": Nucleus(84, 126, "Po"), "after": Nucleus(82, 124, "Pb")},
      {"name": "Neutron Capture Au", "type": ReactionType.neutronCapture, "before": Nucleus(79, 118, "Au"), "after": Nucleus(79, 119, "Au")},
      {"name": "Transmutation N → O", "type": ReactionType.transmutation, "before": Nucleus(7, 7, "N"), "after": Nucleus(8, 9, "O")},
      {"name": "Fission U → Ba + Kr", "type": ReactionType.fission, "before": Nucleus(92, 143, "U"), "after": Nucleus(56, 85, "Ba")},
      {"name": "Fusion H + H → He", "type": ReactionType.fusion, "before": Nucleus(1, 1, "H"), "after": Nucleus(2, 2, "He")},
    ];
  }

  void start() => controller.forward(from: 0);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ================= EQUATION =================

  Widget buildEquation(Nucleus b, Nucleus a, ReactionType type, double t) {
    String before = "¹${b.mass}₍${b.protons}₎${b.symbol}";
    String after = "¹${a.mass}₍${a.protons}₎${a.symbol}";

    String particle = "";

    switch (type) {
      case ReactionType.betaMinus:
        particle = " + β⁻";
        break;
      case ReactionType.betaPlus:
        particle = " + β⁺";
        break;
      case ReactionType.alpha:
        particle = " + ⁴₂He";
        break;
      case ReactionType.electronCapture:
        particle = " + e⁻";
        break;
      case ReactionType.neutronCapture:
        particle = " + n";
        break;
      case ReactionType.transmutation:
        particle = " + H";
        break;
      case ReactionType.fission:
        particle = " + Ba + Kr + 3n";
        break;
      case ReactionType.fusion:
        particle = "";
        break;
    }

    String text;

    if (t < 0.3) {
      text = before;
    } else if (t < 0.7) {
      text = "$before → ?";
    } else {
      text = "$before → $after$particle + Energy";
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final r = reactions[selected];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("المختبر النووي"),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          DropdownButton<int>(
            dropdownColor: Colors.black,
            value: selected,
            items: List.generate(
              reactions.length,
              (i) => DropdownMenuItem(
                value: i,
                child: Text(r["name"],
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
            onChanged: (v) => setState(() => selected = v!),
          ),

          Expanded(
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, __) => CustomPaint(
                painter: NuclearPainter(
                  controller.value,
                  r["before"],
                  r["after"],
                  r["type"],
                ),
              ),
            ),
          ),

          buildEquation(
            r["before"],
            r["after"],
            r["type"],
            controller.value,
          ),

          ElevatedButton(
            onPressed: start,
            child: const Text("ابدأ التفاعل"),
          ),
        ],
      ),
    );
  }
}

// ================= PAINTER =================

class NuclearPainter extends CustomPainter {
  final double t;
  final Nucleus before;
  final Nucleus after;
  final ReactionType type;

  NuclearPainter(this.t, this.before, this.after, this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    double shake = (t > 0.3 && t < 0.5) ? sin(t * 40) * 5 : 0;
    final c = center + Offset(shake, 0);

    _drawAtom(canvas, c, t < 0.5 ? before : after);
    _drawParticles(canvas, c);
    _drawExplosion(canvas, c);
  }

  // ================= ATOM =================

  void _drawAtom(Canvas canvas, Offset center, Nucleus n) {
    canvas.drawCircle(center, 30, Paint()..color = Colors.blueAccent);

    for (int i = 0; i < n.protons; i++) {
      final angle = i * 2 * pi / max(1, n.protons);
      final pos = center + Offset(cos(angle), sin(angle)) * 15;
      canvas.drawCircle(pos, 4, Paint()..color = Colors.red); // +
    }

    for (int i = 0; i < n.neutrons; i++) {
      final angle = i * 2 * pi / max(1, n.neutrons);
      final pos = center + Offset(cos(angle), sin(angle)) * 10;
      canvas.drawCircle(pos, 4, Paint()..color = Colors.grey); // 0
    }

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        i * 50,
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke,
      );
    }

    for (int i = 0; i < n.protons; i++) {
      double angle = (i / max(1, n.protons)) * 2 * pi + t * 2;
      final pos = center + Offset(cos(angle), sin(angle)) * 70;
      canvas.drawCircle(pos, 3, Paint()..color = Colors.purpleAccent); // -
    }
  }

  // ================= PARTICLES (8 REACTIONS) =================

  void _drawParticles(Canvas canvas, Offset center) {
    void drawLabel(Offset p, String text, Color c, double r) {
      canvas.drawCircle(p, r, Paint()..color = c);
    }

    if (type == ReactionType.betaMinus) {
      final p = Offset.lerp(center, center + const Offset(150, 0), t)!;
      drawLabel(p, "β⁻", Colors.yellow, 6);
    }

    if (type == ReactionType.betaPlus) {
      final p = Offset.lerp(center, center + const Offset(-150, 0), t)!;
      drawLabel(p, "β⁺", Colors.green, 6);
    }

    if (type == ReactionType.alpha) {
      final p = Offset.lerp(center, center + const Offset(0, -150), t)!;
      drawLabel(p, "α", Colors.orange, 10);
    }

    if (type == ReactionType.electronCapture) {
      final p = Offset.lerp(center + const Offset(150, 0), center, t)!;
      drawLabel(p, "e⁻", Colors.cyan, 6);
    }

    if (type == ReactionType.neutronCapture) {
      final p = Offset.lerp(center + const Offset(-150, 0), center, t)!;
      drawLabel(p, "n", Colors.white, 6);
    }

    if (type == ReactionType.transmutation) {
      final a = Offset.lerp(center + const Offset(-150, 0), center, t)!;
      drawLabel(a, "α", Colors.orange, 10);

      if (t > 0.6) {
        final p = Offset.lerp(center, center + const Offset(150, 0), t)!;
        drawLabel(p, "p⁺", Colors.red, 6);
      }
    }

    if (type == ReactionType.fission) {
      if (t > 0.5) {
        final l = Offset.lerp(center, center + const Offset(-120, 0), t)!;
        final r = Offset.lerp(center, center + const Offset(120, 0), t)!;

        drawLabel(l, "Ba", Colors.green, 20);
        drawLabel(r, "Kr", Colors.red, 20);

        for (int i = 0; i < 3; i++) {
          final ang = i * 2 * pi / 3;
          final p = center + Offset(cos(ang), sin(ang)) * (t * 150);
          drawLabel(p, "n", Colors.white, 5);
        }
      }
    }

    if (type == ReactionType.fusion) {
      final l = Offset.lerp(center + const Offset(-100, 0), center, t)!;
      final r = Offset.lerp(center + const Offset(100, 0), center, t)!;

      drawLabel(l, "H", Colors.blue, 20);
      drawLabel(r, "H", Colors.blue, 20);

      if (t > 0.7) {
        drawLabel(center, "He", Colors.purple, 30);
      }
    }
  }

  // ================= EXPLOSION =================

  void _drawExplosion(Canvas canvas, Offset center) {
    double p = (t - 0.4) / 0.2;
    if (p < 0 || p > 1) return;

    final radius = p * 120;

    final paint = Paint()
      ..color = Colors.orange.withOpacity(1 - p)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
