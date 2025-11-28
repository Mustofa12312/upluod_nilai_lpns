import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class NoGradePage extends StatefulWidget {
  const NoGradePage({Key? key}) : super(key: key);

  @override
  State<NoGradePage> createState() => _NoGradePageState();
}

class _NoGradePageState extends State<NoGradePage> {
  final students = <Map<String, dynamic>>[].obs;
  final classes = <Map<String, dynamic>>[].obs;
  final subjects = <Map<String, dynamic>>[].obs;

  final selectedClassId = ''.obs;
  final selectedSubjectId = ''.obs;
  final isLoading = false.obs;

  final FocusNode classFocus = FocusNode();
  final FocusNode subjectFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    fetchClasses();
    fetchSubjects();
  }

  // Ambil daftar kelas
  Future<void> fetchClasses() async {
    try {
      final response = await SupabaseService.client.from('classes').select();
      classes.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _glassError("Gagal memuat kelas");
    }
  }

  // Ambil daftar mata pelajaran
  Future<void> fetchSubjects() async {
    try {
      final response = await SupabaseService.client.from('subjects').select();
      subjects.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _glassError("Gagal memuat pelajaran");
    }
  }

  // Ambil nama mata pelajaran dari ID
  String _getSubjectNameById(String id) {
    try {
      final m = subjects.firstWhere((s) => s['id'].toString() == id);
      return m['name'] ?? '-';
    } catch (_) {
      return '-';
    }
  }

  // Ambil siswa yang belum punya nilai
  Future<void> fetchStudentsWithoutGrades() async {
    if (selectedClassId.value.isEmpty || selectedSubjectId.value.isEmpty) {
      _glassWarning("Pilih kelas dan pelajaran");
      return;
    }

    isLoading.value = true;
    try {
      final gradeIdsResponse = await SupabaseService.client
          .from('grades_kuartal')
          .select('student_id')
          .eq('subject_id', int.parse(selectedSubjectId.value));

      final gradeIds = (gradeIdsResponse as List)
          .map((e) => e['student_id'])
          .where((id) => id != null)
          .toList();

      final result = await SupabaseService.client
          .from('students_kuartal')
          .select('id, name, class_id, classes(name)')
          .eq('class_id', int.parse(selectedClassId.value))
          .not('id', 'in', gradeIds.isEmpty ? [0] : gradeIds)
          .order('name', ascending: true);

      students.assignAll(List<Map<String, dynamic>>.from(result));
    } catch (e) {
      _glassError("Gagal mengambil data");
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────── NOTIFIKASI iPHONE GLASS ───────────────────

  void _glassSuccess(String msg) => _glass(msg, Colors.greenAccent);
  void _glassError(String msg) => _glass(msg, Colors.redAccent);
  void _glassWarning(String msg) => _glass(msg, Colors.amberAccent);

  void _glass(String message, Color color) {
    Get.rawSnackbar(
      messageText: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
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
      duration: const Duration(milliseconds: 850),
      animationDuration: const Duration(milliseconds: 420),
      forwardAnimationCurve: Curves.easeOutExpo,
      reverseAnimationCurve: Curves.easeIn,
      overlayBlur: 3,
      overlayColor: Colors.black.withOpacity(0.1),
    );
  }

  // ─────────────────── UI iPHONE ───────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Murid Tanpa Nilai",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionCard([
                _label("Kelas"),
                Obx(
                  () => _iosDropdown(
                    items: classes,
                    selected: selectedClassId.value,
                    onChanged: (v) => selectedClassId.value = v ?? '',
                  ),
                ),
              ]),

              _sectionCard([
                _label("Mata Pelajaran"),
                Obx(
                  () => _iosDropdown(
                    items: subjects,
                    selected: selectedSubjectId.value,
                    onChanged: (v) => selectedSubjectId.value = v ?? '',
                  ),
                ),
              ]),

              const SizedBox(height: 10),

              _iosButton(
                label: "Cari Siswa",
                onTap: fetchStudentsWithoutGrades,
              ),

              const SizedBox(height: 12),

              Expanded(
                child: Obx(() {
                  if (isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    );
                  }

                  if (students.isEmpty) {
                    return Center(
                      child: Text(
                        "Harap melihat semua nilai \n admin tidak akan mengecek lagi nilai yang kosong, murni mengambil nilai yang di sudah uploud oleh para tim",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black45,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final s = students[index];
                      return _sectionCard([
                        Text(
                          s['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Kelas: ${s['classes']?['name']}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          "Mata Pelajaran: ${_getSubjectNameById(selectedSubjectId.value)}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ]);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────── WIDGET HELPER iPHONE ───────────────────

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
            blurRadius: 10,
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

  Widget _iosDropdown({
    required List items,
    required String selected,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: selected.isEmpty ? null : selected,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item['id'].toString(),
              child: Text(
                item['name'],
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _iosButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.4),
              blurRadius: 10,
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
