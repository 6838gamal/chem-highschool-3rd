import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../constants.dart';

enum ParticleType {
  h2,
  o2,
  hcl,
  h2o2,
  butane,
  octane,
  caco3,
  cl2,
  f2,
  co2,
  h2o,
}

class Particle {
  Offset position;
  Offset velocity;
  ParticleType type;
  bool reacted;

  Particle({
    required this.position,
    required this.velocity,
    required this.type,
    this.reacted = false,
  });
}

class ChemistryLabScreen extends StatefulWidget {
  const ChemistryLabScreen({super.key});

  @override
  State<ChemistryLabScreen> createState() => _ChemistryLabScreenState();
}

class _ChemistryLabScreenState extends State<ChemistryLabScreen> {
  final List<Particle> particles = [];
  final Random random = Random();
  Timer? timer;

  bool running = false;
  bool burnerOn = false;

  double worldW = 300;
  double worldH = 500;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  // ---------------- RESET ----------------
  void _reset() {
    timer?.cancel();
    particles.clear();
    running = false;
    burnerOn = false;
    setState(() {});
  }

  // ---------------- ADD PARTICLE ----------------
  void _add(ParticleType type) {
    particles.add(
      Particle(
        position: Offset(
          random.nextDouble() * worldW,
          random.nextDouble() * worldH,
        ),
        velocity: Offset(
          random.nextDouble() * 4 - 2,
          random.nextDouble() * 4 - 2,
        ),
        type: type,
      ),
    );
    setState(() {});
  }

  // ---------------- START / STOP ----------------
  void _start() {
    if (running) return;
    running = true;

    timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      setState(() {
        _move();
        _react();
      });
    });
  }

  void _stop() {
    timer?.cancel();
    running = false;
  }

  // ---------------- MOVEMENT ----------------
  void _move() {
    for (var p in particles) {
      p.position += p.velocity;

      if (p.position.dx < 0 || p.position.dx > worldW) {
        p.velocity = Offset(-p.velocity.dx, p.velocity.dy);
      }

      if (p.position.dy < 0 || p.position.dy > worldH) {
        p.velocity = Offset(p.velocity.dx, -p.velocity.dy);
      }
    }
  }

  // ---------------- REACTIONS ----------------
  void _react() {
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final a = particles[i];
        final b = particles[j];

        if ((a.position - b.position).distanceSquared < 400) {
          _apply(a, b);
        }
      }
    }
  }

  void _apply(Particle a, Particle b) {
    if (a.reacted || b.reacted) return;

    // H2 + Cl2 -> HCl (requires burner)
    if (burnerOn && _pair(a, b, ParticleType.h2, ParticleType.cl2)) {
      a.type = ParticleType.hcl;
      b.type = ParticleType.hcl;
      _freeze(a, b);
    }

    // H2 + F2 -> H2O (simplified)
    if (burnerOn && _pair(a, b, ParticleType.h2, ParticleType.f2)) {
      a.type = ParticleType.h2o;
      b.type = ParticleType.h2o;
      _freeze(a, b);
    }

    // Butane combustion
    if (burnerOn && a.type == ParticleType.butane) {
      a.type = ParticleType.co2;
      _freezeSingle(a);
    }

    // Octane combustion
    if (burnerOn && a.type == ParticleType.octane) {
      a.type = ParticleType.co2;
      _freezeSingle(a);
    }

    // H2O2 decomposition
    if (a.type == ParticleType.h2o2) {
      a.type = ParticleType.h2o;
      _freezeSingle(a);
    }

    // CaCO3 decomposition
    if (burnerOn && a.type == ParticleType.caco3) {
      a.type = ParticleType.co2;
      _freezeSingle(a);
    }
  }

  bool _pair(Particle a, Particle b, ParticleType x, ParticleType y) {
    return (a.type == x && b.type == y) || (a.type == y && b.type == x);
  }

  void _freeze(Particle a, Particle b) {
    a.velocity = Offset.zero;
    b.velocity = Offset.zero;
    a.reacted = true;
    b.reacted = true;
  }

  void _freezeSingle(Particle a) {
    a.velocity = Offset.zero;
    a.reacted = true;
  }

  // ---------------- COLORS ----------------
  Color _color(ParticleType t) {
    switch (t) {
      case ParticleType.h2:
        return Colors.lightBlue;
      case ParticleType.o2:
        return Colors.blue;
      case ParticleType.hcl:
        return Colors.red;
      case ParticleType.h2o2:
        return Colors.purple;
      case ParticleType.butane:
        return Colors.orange;
      case ParticleType.octane:
        return Colors.deepOrange;
      case ParticleType.caco3:
        return Colors.grey;
      case ParticleType.cl2:
        return Colors.green;
      case ParticleType.f2:
        return Colors.yellow;
      case ParticleType.co2:
        return Colors.pink;
      case ParticleType.h2o:
        return Colors.cyan;
    }
  }

  String _name(ParticleType t) {
    return t.toString().split('.').last;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("مختبر التفاعلات الكيميائية"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        children: [
          _leftPanel(),
          Expanded(child: _labArea()),
          _rightPanel(),
        ],
      ),
    );
  }

  // ---------------- LEFT (MATERIALS) ----------------
  Widget _leftPanel() {
    final items = [
      ParticleType.h2,
      ParticleType.o2,
      ParticleType.cl2,
      ParticleType.f2,
      ParticleType.h2o2,
      ParticleType.butane,
      ParticleType.octane,
      ParticleType.caco3,
    ];

    return Container(
      width: 90,
      color: Colors.black26,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items.map((t) {
          return IconButton(
            icon: CircleAvatar(
              backgroundColor: _color(t),
              radius: 12,
              child: Text(
                _name(t)[0],
                style: const TextStyle(fontSize: 10),
              ),
            ),
            onPressed: () => _add(t),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- CENTER LAB ----------------
  Widget _labArea() {
    return LayoutBuilder(
      builder: (context, c) {
        worldW = c.maxWidth;
        worldH = c.maxHeight;

        return Stack(
          children: [
            Center(
              child: Container(
                width: 220,
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyanAccent),
                  color: Colors.black38,
                ),
              ),
            ),

            ...particles.map((p) => Positioned(
                  left: p.position.dx,
                  top: p.position.dy,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _color(p.type),
                      shape: BoxShape.circle,
                      boxShadow: p.reacted
                          ? [
                              BoxShadow(
                                color: _color(p.type).withOpacity(0.7),
                                blurRadius: 10,
                              )
                            ]
                          : null,
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  // ---------------- RIGHT PANEL ----------------
  Widget _rightPanel() {
    return Container(
      width: 90,
      color: Colors.black26,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Switch(
            value: running,
            onChanged: (v) {
              setState(() {
                running = v;
                if (v) _start();
                else _stop();
              });
            },
          ),

          const SizedBox(height: 10),

          IconButton(
            icon: Icon(
              Icons.local_fire_department,
              color: burnerOn ? Colors.red : Colors.brown,
            ),
            onPressed: () {
              setState(() => burnerOn = !burnerOn);
            },
          ),

          const SizedBox(height: 10),

          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
