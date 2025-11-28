import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController idController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();

  final Rxn<Map<String, dynamic>> studentData = Rxn<Map<String, dynamic>>();
  final RxBool isLoading = false.obs;
  final RxBool isSubjectsLoading = false.obs;
  final RxList<Map<String, dynamic>> subjects = <Map<String, dynamic>>[].obs;
  final RxnInt selectedSubjectId = RxnInt();

  final FocusNode idFocus = FocusNode();
  final FocusNode gradeFocus = FocusNode();

  late AnimationController fadeController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  bool _btnPressed = false;

  @override
  void initState() {
    super.initState();
    fetchSubjects();

    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeInOut,
    );
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(fadeAnimation);

    ever(studentData, (data) {
      if (data != null) fadeController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    idController.dispose();
    gradeController.dispose();
    idFocus.dispose();
    gradeFocus.dispose();
    fadeController.dispose();
    super.dispose();
  }

  // ─────────────────── LOGIKA UTAMA ───────────────────

  Future<void> fetchSubjects() async {
    try {
      isSubjectsLoading.value = true;
      final response = await SupabaseService.client
          .from('subjects')
          .select('id, name');
      subjects.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      showGlassError("Gagal memuat mata pelajaran");
    } finally {
      isSubjectsLoading.value = false;
    }
  }

  Future<void> fetchStudentById() async {
    final idText = idController.text.trim();
    if (idText.isEmpty) {
      showGlassWarning("Masukkan ID siswa terlebih dahulu");
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      isLoading.value = true;

      final response = await SupabaseService.client
          .from('students_kuartal')
          .select('id, name, class_id, classes(name)')
          .eq('id', int.parse(idText))
          .maybeSingle();

      if (response != null) {
        studentData.value = response;

        Future.delayed(const Duration(milliseconds: 350), () {
          gradeFocus.requestFocus();
        });
      } else {
        studentData.value = null;
        showGlassWarning("ID tidak ditemukan");
      }
    } catch (e) {
      showGlassError("Terjadi kesalahan");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadGrade() async {
    if (studentData.value == null) {
      showGlassWarning("Cari siswa terlebih dahulu");
      return;
    }
    if (gradeController.text.isEmpty) {
      showGlassWarning("Masukkan nilai");
      return;
    }
    if (selectedSubjectId.value == null) {
      showGlassWarning("Pilih mata pelajaran");
      return;
    }

    final gradeValue = double.tryParse(gradeController.text);
    if (gradeValue == null || gradeValue < 0 || gradeValue > 100) {
      showGlassWarning("Nilai harus 0–100");
      return;
    }

    try {
      await SupabaseService.client.from('grades_kuartal').insert({
        'student_id': studentData.value!['id'],
        'subject_id': selectedSubjectId.value,
        'grade': gradeValue,
      });

      showGlassSuccess("Nilai berhasil diupload!");

      idController.clear();
      gradeController.clear();
      studentData.value = null;
      idFocus.requestFocus();
    } catch (e) {
      showGlassError("Upload gagal");
    }
  }

  // ─────────────────── NOTIFIKASI GLASS (0.7 detik) ───────────────────

  void showGlassSuccess(String msg) => _glass(msg, Colors.greenAccent);
  void showGlassError(String msg) => _glass(msg, Colors.redAccent);
  void showGlassWarning(String msg) => _glass(msg, Colors.amberAccent);

  void _glass(String message, Color color) {
    Get.rawSnackbar(
      messageText: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.22),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
                width: 1.2,
              ),
            ),
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 20,
      duration: const Duration(milliseconds: 700), // HILANG < 1 DETIK
      animationDuration: const Duration(milliseconds: 350),
      forwardAnimationCurve: Curves.easeOutExpo,
      reverseAnimationCurve: Curves.easeIn,
      overlayBlur: 2,
      overlayColor: Colors.black.withOpacity(0.08),
    );
  }

  // ─────────────────── UI iPHONE ───────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Warna khas iOS
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        title: Text(
          "Input Nilai Kuartal",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              _sectionCard([
                _label("Mata Pelajaran"),
                Obx(
                  () => isSubjectsLoading.value
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue,
                          ),
                        )
                      : _iosDropdown(),
                ),
              ]),

              _sectionCard([
                _label("ID Siswa"),
                _iosTextField(
                  controller: idController,
                  hint: "Masukkan ID",
                  icon: Icons.search,
                  focusNode: idFocus,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => fetchStudentById(),
                ),
              ]),

              Obx(() {
                if (isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                if (studentData.value == null) return const SizedBox();

                final s = studentData.value!;
                return FadeTransition(
                  opacity: fadeAnimation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: _sectionCard([
                      _label("Data Siswa"),
                      Text(
                        s['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Kelas: ${s['classes']?['name']}",
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: 15,
                        ),
                      ),
                    ]),
                  ),
                );
              }),

              _sectionCard([
                _label("Nilai Kuartal"),
                _iosTextField(
                  controller: gradeController,
                  hint: "Masukkan Nilai",
                  focusNode: gradeFocus,
                  keyboardType: TextInputType.number,
                ),
              ]),

              const SizedBox(height: 12),
              _iosButton(label: "Input Nilai", onTap: uploadGrade),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────── WIDGET iOS ───────────────────

  Widget _sectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _iosDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedSubjectId.value,
      dropdownColor: Colors.white,
      iconEnabledColor: Colors.black45,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: subjects
          .map(
            (s) => DropdownMenuItem<int>(
              value: s['id'],
              child: Text(
                s['name'],
                style: const TextStyle(color: Colors.black),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => selectedSubjectId.value = v,
    );
  }

  Widget _iosTextField({
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      cursorColor: Colors.black,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.black38),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.black38, size: 20)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _iosButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _btnPressed = true),
      onTapUp: (_) => setState(() => _btnPressed = false),
      onTapCancel: () => setState(() => _btnPressed = false),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 52,
        decoration: BoxDecoration(
          color: _btnPressed
              ? Colors.blueAccent.withOpacity(0.55)
              : Colors.blueAccent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.35),
              blurRadius: _btnPressed ? 3 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
