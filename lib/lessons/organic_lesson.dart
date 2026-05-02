import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../constants.dart';

class Atom {
  Offset position;
  Offset velocity;
  String type;
  int bonds = 0;

  Atom(this.position, this.velocity, this.type);

  int get maxBonds {
    switch (type) {
      case "H": return 1;
      case "O": return 2;
      case "C": return 4;
      default: return 0;
    }
  }

  bool canBond() => bonds < maxBonds;
}

class Bond {
  Atom a; Atom b;
  Bond(this.a, this.b);
}

class AlcoholScreen extends StatefulWidget {
  const AlcoholScreen({super.key});

  @override
  _AlcoholScreenState createState() => _AlcoholScreenState();
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
    atoms = List.generate(9, (i) {
      String type = (i < 2) ? "C" : (i < 8) ? "H" : "O";
      return Atom(
        Offset(random.nextDouble() * 300 + 50, random.nextDouble() * 400 + 50),
        Offset(random.nextDouble() * 3 - 1.5, random.nextDouble() * 3 - 1.5),
        type,
      );
    });
  }

  void startSimulation() {
    timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      updatePhysics();
    });
  }

  void updatePhysics() {
    setState(() {
      moveAtoms();
      createBonds();
      validateMolecule();
    });
  }

  void moveAtoms() {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height * 0.6;

    for (var a in atoms) {
      a.position += a.velocity;
      if (a.position.dx < 20 || a.position.dx > width - 20) a.velocity = Offset(-a.velocity.dx, a.velocity.dy);
      if (a.position.dy < 20 || a.position.dy > height - 20) a.velocity = Offset(a.velocity.dx, -a.velocity.dy);
    }
  }

  void createBonds() {
    for (int i = 0; i < atoms.length; i++) {
      for (int j = i + 1; j < atoms.length; j++) {
        Atom a = atoms[i];
        Atom b = atoms[j];
        double dist = (a.position - b.position).distance;

        if (dist < 50 && a.canBond() && b.canBond() && !alreadyBonded(a, b)) {
          bonds.add(Bond(a, b));
          a.bonds++;
          b.bonds++;
        }
      }
    }
  }

  bool alreadyBonded(Atom a, Atom b) => bonds.any((bond) => (bond.a == a && bond.b == b) || (bond.a == b && bond.b == a));

  void validateMolecule() {
    if (!ethanolFormed && bonds.length >= 8) {
      ethanolFormed = true;
    }
  }

  Color atomColor(String type) {
    switch (type) {
      case "C": return Colors.grey.shade900;
      case "O": return Colors.redAccent;
      case "H": return Colors.lightBlueAccent;
      default: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("الكيمياء العضوية: الأغوال"), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          _buildStatusHeader(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.neonBlue.withOpacity(0.2)),
              ),
              child: CustomPaint(
                painter: MoleculePainter(atoms, bonds, atomColor),
                child: Container(),
              ),
            ),
          ),
          _buildInfoPanel(),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ethanolFormed ? Colors.green.withOpacity(0.2) : AppColors.glassWhite,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ethanolFormed ? Colors.green : Colors.white10),
      ),
      child: Text(
        ethanolFormed ? "✅ تم تكوين جزيء الإيثانول بنجاح!" : "🧪 جارِ محاكاة التصادمات لتكوين C₂H₅OH",
        style: TextStyle(color: ethanolFormed ? Colors.greenAccent : Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.glassWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat("C", "2", Colors.black),
          _stat("H", "6", Colors.lightBlueAccent),
          _stat("O", "1", Colors.redAccent),
          _stat("Bonds", "${bonds.length}/8", AppColors.neonBlue),
        ],
      ),
    );
  }

  Widget _stat(String label, String val, Color color) {
    return Column(children: [Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)), Text(val, style: const TextStyle(color: Colors.white70))]);
  }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }
}

class MoleculePainter extends CustomPainter {
  List<Atom> atoms;
  List<Bond> bonds;
  Function colorFn;

  MoleculePainter(this.atoms, this.bonds, this.colorFn);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (var bond in bonds) {
      paint.color = Colors.white24;
      paint.strokeWidth = 4;
      canvas.drawLine(bond.a.position, bond.b.position, paint);
    }

    for (var atom in atoms) {
      paint.color = colorFn(atom.type);
      canvas.drawCircle(atom.position, 16, paint);
      // إضافة تأثير توهج (Glow)
      paint.color = colorFn(atom.type).withOpacity(0.3);
      canvas.drawCircle(atom.position, 22, paint);

      final textPainter = TextPainter(
        text: TextSpan(text: atom.type, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, atom.position + const Offset(-6, -10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
