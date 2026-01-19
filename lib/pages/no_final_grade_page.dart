import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class NoFinalGradePage extends StatefulWidget {
  const NoFinalGradePage({Key? key}) : super(key: key);

  @override
  State<NoFinalGradePage> createState() => _NoFinalGradePageState();
}

class _NoFinalGradePageState extends State<NoFinalGradePage> {
  final students = <Map<String, dynamic>>[].obs;
  final classes = <Map<String, dynamic>>[].obs;
  final subjects = <Map<String, dynamic>>[].obs;

  final selectedClassId = ''.obs;
  final selectedSubjectId = ''.obs;
  final isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    fetchClasses();
    fetchSubjects();
  }

  // ───────── DATA ─────────

  Future<void> fetchClasses() async {
    try {
      final res = await SupabaseService.client.from('classes').select();
      classes.assignAll(List<Map<String, dynamic>>.from(res));
    } catch (_) {
      _glass("Gagal memuat kelas", Colors.redAccent);
    }
  }

  Future<void> fetchSubjects() async {
    try {
      final res = await SupabaseService.client.from('subjects').select();
      subjects.assignAll(List<Map<String, dynamic>>.from(res));
    } catch (_) {
      _glass("Gagal memuat pelajaran", Colors.redAccent);
    }
  }

  String _getSubjectNameById(String id) {
    try {
      return subjects.firstWhere((s) => s['id'].toString() == id)['name'];
    } catch (_) {
      return '-';
    }
  }

  Future<void> fetchStudentsWithoutGrades() async {
    if (selectedClassId.value.isEmpty || selectedSubjectId.value.isEmpty) {
      _glass("Pilih kelas & pelajaran terlebih dahulu", Colors.amberAccent);
      return;
    }

    isLoading.value = true;
    try {
      final gradeIdsRes = await SupabaseService.client
          .from('grades_ujian_akhir')
          .select('student_id')
          .eq('subject_id', int.parse(selectedSubjectId.value));

      final gradeIds = (gradeIdsRes as List)
          .map((e) => e['student_id'])
          .where((e) => e != null)
          .toList();

      final res = await SupabaseService.client
          .from('students_ujian_akhir')
          .select('id, name, class_id, classes(name)')
          .eq('class_id', int.parse(selectedClassId.value))
          .not('id', 'in', gradeIds.isEmpty ? [0] : gradeIds)
          .order('name');

      students.assignAll(List<Map<String, dynamic>>.from(res));
    } catch (_) {
      _glass("Gagal mengambil data", Colors.redAccent);
    } finally {
      isLoading.value = false;
    }
  }

  // ───────── GLASS SNACKBAR ─────────

  void _glass(String msg, Color color) {
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
                color: Colors.white.withOpacity(0.4),
                width: 1.2,
              ),
            ),
            child: Text(
              msg,
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
      duration: const Duration(milliseconds: 900),
    );
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Tanpa Nilai Ujian",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              _sectionCard([
                _label("Kelas"),
                Obx(() => _iosDropdown(classes, selectedClassId)),
              ]),
              _sectionCard([
                _label("Mata Pelajaran"),
                Obx(() => _iosDropdown(subjects, selectedSubjectId)),
              ]),
              const SizedBox(height: 12),
              _iosButton("Cari Siswa", fetchStudentsWithoutGrades),
              const SizedBox(height: 10),

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
                        "Tidak ada siswa tanpa nilai",
                        style: GoogleFonts.poppins(
                          color: Colors.black45,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (_, i) {
                      final s = students[i];
                      return _sectionCard([
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s['name'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
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
                                    "Pelajaran: ${_getSubjectNameById(selectedSubjectId.value)}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 🆔 ID SUPABASE – KECIL & MINIMAL
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "ID ${s['id']}",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ],
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

  // ───────── WIDGET iOS ─────────

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

  Widget _iosDropdown(List items, RxString selected) {
    return DropdownButtonFormField<String>(
      value: selected.value.isEmpty ? null : selected.value,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e['id'].toString(),
              child: Text(
                e['name'],
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => selected.value = v ?? '',
    );
  }

  Widget _iosButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.35),
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
