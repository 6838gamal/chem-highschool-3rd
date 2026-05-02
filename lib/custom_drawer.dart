import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
import 'login_screen.dart';

class CustomDrawer extends StatelessWidget {
  final String studentName;
  const CustomDrawer({super.key, required this.studentName});

  // ================= روابط =================
  Future<void> _openWhatsApp() async {
    final url = Uri.parse("https://wa.me/963947293949");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _openInstagram() async {
    final url = Uri.parse("https://instagram.com/Chemistry.360");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _openFacebook() async {
    final url = Uri.parse("https://facebook.com/Chemistry360");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // 🔷 الهيدر
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1D1E33)),
            accountName: Text(
              studentName,
              style: const TextStyle(
                color: AppColors.neonBlue,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.blueAccent, blurRadius: 10),
                ],
              ),
            ),
            accountEmail: const Text(
              "المستوى الثالث - علمي",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppColors.neonPurple,
              child: Icon(Icons.person, color: Colors.white, size: 40),
            ),
          ),

          // 👨‍🏫 بطاقة المعلم
          _buildTeacherCard(context),

          // 📊 عناصر إضافية (احترافية)
          ListTile(
            leading: const Icon(Icons.science, color: Colors.cyanAccent),
            title: const Text("الدروس"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.greenAccent),
            title: const Text("تقدمي"),
            onTap: () {},
          ),

          const Spacer(),

          // 🚪 تسجيل الخروج
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("تسجيل الخروج"),
            onTap: () => _confirmLogout(context),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ================= بطاقة المعلم =================
  Widget _buildTeacherCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.neonBlue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.neonBlue,
            child: Icon(Icons.school, color: Colors.white),
          ),
          const SizedBox(height: 10),

          const Text(
            "عدنان عثمان",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            "مدرس كيمياء - Chemistry 360",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            "اطلب النماذج الوزارية مباشرة:",
            style: TextStyle(color: Colors.white),
          ),

          const SizedBox(height: 10),

          // 🔥 زر رئيسي (CTA)
          ElevatedButton.icon(
            onPressed: _openWhatsApp,
            icon: const Icon(Icons.chat),
            label: const Text("اطلب الآن عبر واتساب"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 📱 روابط سوشيال
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _openInstagram,
                icon: const Icon(Icons.camera_alt, color: Colors.purple),
              ),
              IconButton(
                onPressed: _openFacebook,
                icon: const Icon(Icons.facebook, color: Colors.blue),
              ),
              IconButton(
                onPressed: _openWhatsApp,
                icon: const Icon(Icons.phone, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= تأكيد الخروج =================
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تأكيد"),
        content: const Text("هل تريد تسجيل الخروج؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text("خروج"),
          ),
        ],
      ),
    );
  }
}
