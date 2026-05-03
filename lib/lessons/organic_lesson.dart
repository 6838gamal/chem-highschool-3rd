import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../constants.dart';

class Atom {
  Offset position;
  Offset velocity;
  Offset force = Offset.zero;
  String type;
  int bonds = 0;

  Atom(this.position, this.velocity, this.type);

  double get mass {
    switch (type) {
      case "H":
        return 1;
      case "O":
        return 16;
      case "C":
        return 12;
      default:
        return 1;
    }
  }

  int get maxBonds {
    switch (type) {
      case "H":
        return 1;
      case "O":
        return 2;
      case "C":
        return 4;
      default:
        return 0;
    }
  }

  bool canBond() => bonds < maxBonds;
}

class Bond {
  Atom a;
  Atom b;
  Bond(this.a, this.b);
}

class AlcoholScreen extends StatefulWidget {
  const AlcoholScreen({super.key});

  @override
  State<AlcoholScreen> createState() => _AlcoholScreenState();
}

class _AlcoholScreenState extends State<AlcoholScreen> {
  List<Atom> atoms = [];
  List<Bond> bonds = [];
  Timer? timer;
  Random random = Random();
  bool ethanolFormed = false;

  @override
  void initState() {
    super.initState();
    initAtoms();
    startSimulation();
  }

  void initAtoms() {
    atoms = [
      Atom(Offset(120, 200), randomVel(), "C"),
      Atom(Offset(220, 200), randomVel(), "C"),
      Atom(Offset(170, 120), randomVel(), "O"),

      Atom(Offset(80, 300), randomVel(), "H"),
      Atom(Offset(130, 320), randomVel(), "H"),
      Atom(Offset(180, 330), randomVel(), "H"),
      Atom(Offset(230, 320), randomVel(), "H"),
      Atom(Offset(280, 300), randomVel(), "H"),
      Atom(Offset(320, 260), randomVel(), "H"),
    ];
  }

  Offset randomVel() {
    return Offset(random.nextDouble() * 2 - 1, random.nextDouble() * 2 - 1);
  }

  void startSimulation() {
    timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      updatePhysics();
    });
  }

  void updatePhysics() {
    setState(() {
      applyForces();
      applyBondForces();
      moveAtoms();
      createBonds();
      validateMolecule();
    });
  }

  // 🔥 القوى بين الذرات (تنافر + جذب)
  void applyForces() {
    const double repulsion = 6000;
    const double attraction = 0.015;

    for (var a in atoms) {
      a.force = Offset.zero;

      for (var b in atoms) {
        if (a == b) continue;

        Offset dir = a.position - b.position;
        double dist = dir.distance + 0.1;
        Offset norm = dir / dist;

        // تنافر قوي عند القرب
        a.force += norm * (repulsion / (dist * dist));

        // جذب خفيف عند المسافات المتوسطة
        if (dist < 140) {
          a.force -= norm * attraction * dist;
        }
      }
    }
  }

  // 🧲 الروابط كنابض (Spring physics)
  void applyBondForces() {
    const double bondStrength = 0.03;
    const double idealLength = 40;

    for (var bond in bonds) {
      Offset dir = bond.b.position - bond.a.position;
      double dist = dir.distance + 0.1;
      Offset norm = dir / dist;

      double forceMag = bondStrength * (dist - idealLength);

      bond.a.force += norm * forceMag;
      bond.b.force -= norm * forceMag;
    }
  }

  // 🚀 حركة فيزيائية حقيقية
  void moveAtoms() {
    final size = MediaQuery.of(context).size;
    double width = size.width;
    double height = size.height * 0.6;

    for (var a in atoms) {
      Offset acceleration = a.force / a.mass;

      a.velocity = (a.velocity + acceleration) * 0.97;
      a.position += a.velocity;

      // حدود الشاشة
      if (a.position.dx < 20 || a.position.dx > width - 20) {
        a.velocity = Offset(-a.velocity.dx * 0.6, a.velocity.dy);
      }

      if (a.position.dy < 20 || a.position.dy > height - 20) {
        a.velocity = Offset(a.velocity.dx, -a.velocity.dy * 0.6);
      }
    }
  }

  // 🔗 تكوين الروابط
  void createBonds() {
    for (int i = 0; i < atoms.length; i++) {
      for (int j = i + 1; j < atoms.length; j++) {
        final a = atoms[i];
        final b = atoms[j];

        double dist = (a.position - b.position).distance;

        if (dist < 50 &&
            a.canBond() &&
            b.canBond() &&
            !alreadyBonded(a, b)) {
          bonds.add(Bond(a, b));
          a.bonds++;
          b.bonds++;
        }
      }
    }
  }

  bool alreadyBonded(Atom a, Atom b) {
    return bonds.any((bond) =>
        (bond.a == a && bond.b == b) || (bond.a == b && bond.b == a));
  }

  // 🧪 تحقق من الإيثانول
  void validateMolecule() {
    if (!ethanolFormed) {
      int c = atoms.where((e) => e.type == "C").length;
      int h = atoms.where((e) => e.type == "H").length;
      int o = atoms.where((e) => e.type == "O").length;

      if (c == 2 && h >= 6 && o == 1 && bonds.length >= 7) {
        ethanolFormed = true;
      }
    }
  }

  Color atomColor(String type) {
    switch (type) {
      case "C":
        return Colors.grey.shade900;
      case "O":
        return Colors.redAccent;
      case "H":
        return Colors.lightBlueAccent;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("محاكاة الإيثانول - فيزياء جزيئية"),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(30),
              ),
              child: CustomPaint(
                painter: MoleculePainter(atoms, bonds, atomColor),
                child: Container(),
              ),
            ),
          ),
          _info(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ethanolFormed
            ? Colors.green.withOpacity(0.2)
            : Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ethanolFormed
            ? "✅ جزيء الإيثانول مستقر"
            : "🧪 المحاكاة الفيزيائية تعمل...",
        style: TextStyle(
          color: ethanolFormed ? Colors.greenAccent : Colors.white,
        ),
      ),
    );
  }

  Widget _info() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat("C", "2"),
          _stat("H", "6"),
          _stat("O", "1"),
          _stat("Bonds", "${bonds.length}"),
        ],
      ),
    );
  }

  Widget _stat(String a, String b) {
    return Column(
      children: [
        Text(a, style: const TextStyle(color: Colors.white)),
        Text(b, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

class MoleculePainter extends CustomPainter {
  final List<Atom> atoms;
  final List<Bond> bonds;
  final Function colorFn;

  MoleculePainter(this.atoms, this.bonds, this.colorFn);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;

    // الروابط
    for (var b in bonds) {
      paint
        ..color = Colors.white24
        ..strokeWidth = 2.5;
      canvas.drawLine(b.a.position, b.b.position, paint);
    }

    // الذرات
    for (var a in atoms) {
      final c = colorFn(a.type);

      paint
        ..color = c
        ..style = PaintingStyle.fill;

      canvas.drawCircle(a.position, 13, paint);

      paint.color = c.withOpacity(0.25);
      canvas.drawCircle(a.position, 20, paint);

      final tp = TextPainter(
        text: TextSpan(
          text: a.type,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, a.position + const Offset(-5, -8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
