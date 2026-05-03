import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../constants.dart';

/// ================= TYPES =================
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

/// ================= PARTICLE =================
class Particle {
  Offset position;
  Offset velocity;
  ParticleType type;

  bool reacted;
  bool reacting;
  double reactionProgress;

  Particle({
    required this.position,
    required this.velocity,
    required this.type,
    this.reacted = false,
    this.reacting = false,
    this.reactionProgress = 0,
  });
}

/// ================= REACTION =================
class Reaction {
  final List<ParticleType> inputs;
  final List<ParticleType> outputs;
  final bool needHeat;
  final bool needCatalyst;
  final String equation;

  Reaction({
    required this.inputs,
    required this.outputs,
    required this.equation,
    this.needHeat = false,
    this.needCatalyst = false,
  });
}

/// ================= MAIN SCREEN =================
class ChemistryLabScreen extends StatefulWidget {
  const ChemistryLabScreen({super.key});

  @override
  State<ChemistryLabScreen> createState() =>
      _ChemistryLabScreenState();
}

/// ================= STATE =================
class _ChemistryLabScreenState extends State<ChemistryLabScreen> {
  final List<Particle> particles = [];
  final Random random = Random();
  Timer? timer;

  double worldW = 300;
  double worldH = 500;

  bool burnerOn = false;
  bool catalystOn = false;

  ParticleType? selectedMaterial;
  ParticleType? selectedPowder;

  Reaction? currentReaction;

  String reactionStatus = "";

  /// ================= REACTIONS DATABASE =================
  final List<Reaction> reactions = [
    // تفاعلات المواد السائلة والغازية
    Reaction(
      inputs: [ParticleType.h2, ParticleType.cl2],
      outputs: [ParticleType.hcl, ParticleType.hcl],
      needHeat: true,
      equation: "H₂ + Cl₂ → 2HCl (بالحرارة)",
    ),
    Reaction(
      inputs: [ParticleType.h2, ParticleType.o2],
      outputs: [ParticleType.h2o, ParticleType.h2o],
      needHeat: true,
      equation: "2H₂ + O₂ → 2H₂O (احتراق)",
    ),
    // تفاعلات المساحيق
    Reaction(
      inputs: [ParticleType.caco3],
      outputs: [ParticleType.co2],
      needHeat: true,
      equation: "CaCO₃ → CO₂ + CaO (بالحرارة)",
    ),
    // تفاعلات التحلل بالعامل المساعد
    Reaction(
      inputs: [ParticleType.h2o2],
      outputs: [ParticleType.h2o, ParticleType.o2],
      needCatalyst: true,
      equation: "2H₂O₂ → 2H₂O + O₂ (بالعامل المساعد)",
    ),
  ];

  // قائمة المواد السائلة والغازية
  final List<ParticleType> materials = [
    ParticleType.h2,
    ParticleType.o2,
    ParticleType.cl2,
    ParticleType.h2o2,
  ];

  // قائمة المساحيق الصلبة
  final List<ParticleType> powders = [
    ParticleType.caco3,
  ];

  @override
  void initState() {
    super.initState();
    _startLoop();
  }

  /// ================= LOOP =================
  void _startLoop() {
    timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      setState(() {
        _move();
        _detectReaction();
        _handleCollisions();
      });
    });
  }

  /// ================= INJECT FROM TUBE =================
  void _injectFromTube() {
    if (selectedMaterial == null) return;

    particles.add(
      Particle(
        position: Offset(worldW / 2, 0),
        velocity: const Offset(0, 3),
        type: selectedMaterial!,
      ),
    );

    if (selectedPowder != null) {
      particles.add(
        Particle(
          position: Offset(worldW / 2 + 10, 0),
          velocity: const Offset(0, 3),
          type: selectedPowder!,
        ),
      );
    }
  }

  /// ================= MOVEMENT =================
  void _move() {
    // حساب حدود الوعاء (مركز الشاشة)
    double containerCenterX = worldW / 2;
    double containerCenterY = worldH / 2;
    double containerWidth = 220;
    double containerHeight = 320;
    double containerLeft = containerCenterX - containerWidth / 2;
    double containerRight = containerCenterX + containerWidth / 2;
    double containerTop = containerCenterY - containerHeight / 2;
    double containerBottom = containerCenterY + containerHeight / 2;

    for (var p in particles) {
      if (p.reacting) {
        p.reactionProgress += 0.05;

        // اهتزاز عشوائي أثناء التفاعل
        p.position += Offset(
          (random.nextDouble() - 0.5) * 4,
          (random.nextDouble() - 0.5) * 4,
        );

        if (p.reactionProgress >= 1) {
          p.reacting = false;
          p.reacted = true;
          p.velocity = Offset.zero;
        }
        continue;
      }

      /// نزول داخل الأنبوب (قبل دخول الوعاء)
      if (p.position.dy < 150) {
        p.velocity = const Offset(0, 3);
      } else {
        /// داخل الوعاء - حركة بطيئة مع الجاذبية
        p.velocity = Offset(p.velocity.dx * 0.98, p.velocity.dy + 0.1);
      }

      p.position += p.velocity;

      /// حدود الوعاء - الجزيئات تبقى داخله
      if (p.position.dy > containerBottom - 15) {
        p.position = Offset(p.position.dx, containerBottom - 15);
        p.velocity = Offset(p.velocity.dx * 0.9, 0);
      }

      if (p.position.dx < containerLeft + 10) {
        p.position = Offset(containerLeft + 10, p.position.dy);
        p.velocity = Offset(-p.velocity.dx * 0.9, p.velocity.dy);
      }

      if (p.position.dx > containerRight - 10) {
        p.position = Offset(containerRight - 10, p.position.dy);
        p.velocity = Offset(-p.velocity.dx * 0.9, p.velocity.dy);
      }
    }
  }

  /// ================= DETECT REACTION =================
  void _detectReaction() {
    if (selectedMaterial == null) {
      currentReaction = null;
      reactionStatus = "";
      return;
    }

    for (var r in reactions) {
      // تحقق من تطابق المادة
      bool hasMaterial = r.inputs.contains(selectedMaterial);
      
      // تحقق من تطابق المسحوق (إن وجد)
      bool hasPowder = true;
      if (selectedPowder != null) {
        hasPowder = r.inputs.contains(selectedPowder);
      }

      // تحقق من احتياجات الحرارة والعامل المساعد
      bool meetsConditions = true;
      if (r.needHeat && !burnerOn) meetsConditions = false;
      if (r.needCatalyst && !catalystOn) meetsConditions = false;

      // إذا تطابقت جميع الشروط
      if (hasMaterial && hasPowder && meetsConditions) {
        currentReaction = r;
        return;
      }
    }

    currentReaction = null;
  }

  /// ================= COLLISIONS =================
  void _handleCollisions() {
    if (selectedMaterial == null) {
      reactionStatus = "اختر مادة";
      return;
    }

    // تصفية الجزيئات غير المتفاعلة والموجودة في الوعاء
    List<Particle> available = particles
        .where((p) => p.position.dy > 150 && !p.reacted && !p.reacting)
        .toList();

    if (available.isEmpty) {
      return;
    }

    if (currentReaction == null) {
      reactionStatus = "لا يوجد تفاعل متاح";
      return;
    }

    // تفاعل بمادة واحدة فقط (مثل تحلل CaCO3 أو H2O2)
    if (currentReaction!.inputs.length == 1) {
      for (var p in available) {
        if (currentReaction!.inputs.contains(p.type)) {
          _executeReaction(p, null, currentReaction!);
          reactionStatus = "✔ تفاعل: ${currentReaction!.equation}";
          return;
        }
      }
    }
    // تفاعل بمادتين (مثل H2 + Cl2)
    else if (available.length >= 2) {
      for (int i = 0; i < available.length; i++) {
        for (int j = i + 1; j < available.length; j++) {
          final a = available[i];
          final b = available[j];

          // تحقق من القرب بين الجزيئات
          double distance = (a.position - b.position).distance;
          if (distance < 30) {
            if (_matches(a, b, currentReaction!)) {
              _executeReaction(a, b, currentReaction!);
              reactionStatus = "✔ تفاعل: ${currentReaction!.equation}";
              return;
            }
          }
        }
      }
    }
  }

  bool _matches(Particle a, Particle b, Reaction r) {
    return (r.inputs.contains(a.type) &&
            r.inputs.contains(b.type)) ||
        (r.inputs.contains(b.type) &&
            r.inputs.contains(a.type));
  }

  /// ================= EXECUTE REACTION =================
  void _executeReaction(
      Particle a, Particle? b, Reaction r) {
    a.reacting = true;
    a.reactionProgress = 0;
    a.velocity = Offset.zero;

    if (b != null) {
      b.reacting = true;
      b.reactionProgress = 0;
      b.velocity = Offset.zero;

      if (r.outputs.isNotEmpty) {
        a.type = r.outputs.first;
        if (r.outputs.length > 1) {
          b.type = r.outputs[1];
        } else {
          b.type = r.outputs.first;
        }
      }
    } else {
      // تفاعل بمادة واحدة فقط
      if (r.outputs.isNotEmpty) {
        a.type = r.outputs.first;
      }
    }
  }

  /// ================= COLORS =================
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

  String _name(ParticleType t) =>
      t.toString().split('.').last;

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("مختبر التفاعلات الكيميائية"),
      ),
      body: Column(
        children: [
          _topPanel(),
          Expanded(child: _labArea()),
        ],
      ),
    );
  }

  /// ================= TOP PANEL =================
  Widget _topPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black26,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Tooltip(
              message: 'الحرارة',
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                  Switch(
                    value: burnerOn,
                    onChanged: (v) =>
                        setState(() => burnerOn = v),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'العامل المساعد',
              child: Row(
                children: [
                  const Text('⚗️', style: TextStyle(fontSize: 20)),
                  Switch(
                    value: catalystOn,
                    onChanged: (v) =>
                        setState(() => catalystOn = v),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // قائمة المواد
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("🧪 مادة", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    DropdownButton<ParticleType>(
                      isExpanded: true,
                      hint: const Text("اختر مادة", style: TextStyle(color: Colors.white60, fontSize: 13)),
                      dropdownColor: Colors.grey[850],
                      value: selectedMaterial,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      onChanged: (v) {
                        setState(() {
                          selectedMaterial = v;
                          _detectReaction();
                        });
                      },
                      items: materials
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(_name(e)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // قائمة المساحيق
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("💊 مسحوق", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    DropdownButton<ParticleType?>(
                      isExpanded: true,
                      hint: const Text("اختياري", style: TextStyle(color: Colors.white60, fontSize: 13)),
                      dropdownColor: Colors.grey[850],
                      value: selectedPowder,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      onChanged: (v) {
                        setState(() {
                          selectedPowder = v;
                          _detectReaction();
                        });
                      },
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("بدون"),
                        ),
                        ...powders
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(_name(e)),
                                ))
                            .toList(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _injectFromTube,
              icon: const Icon(Icons.arrow_downward),
              label: const Text("إدخال"),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= LAB AREA =================
  Widget _labArea() {
    return LayoutBuilder(
      builder: (context, c) {
        worldW = c.maxWidth;
        worldH = c.maxHeight;

        return Stack(
          children: [
            /// الأنبوب
            Positioned(
              top: 0,
              left: worldW / 2 - 10,
              child: Container(
                width: 20,
                height: 150,
                color: Colors.white24,
              ),
            ),

            /// الوعاء
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

            /// النص
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    currentReaction?.equation ??
                        "لا يوجد تفاعل",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reactionStatus,
                    style: TextStyle(
                      color: reactionStatus.startsWith("✔")
                          ? Colors.green
                          : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// النار
            Positioned(
              bottom: 10,
              left: worldW / 2 - 20,
              child: Icon(
                Icons.local_fire_department,
                color: burnerOn
                    ? Colors.red
                    : Colors.grey,
                size: 40,
              ),
            ),

            /// الجسيمات
            ...particles.map((p) => Positioned(
                  left: p.position.dx,
                  top: p.position.dy,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _color(p.type),
                      shape: BoxShape.circle,
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
