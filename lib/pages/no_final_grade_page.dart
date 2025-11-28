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

  final FocusNode classFocus = FocusNode();
  final FocusNode subjectFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    fetchClasses();
    fetchSubjects();
  }

  // FETCH CLASSES
  Future<void> fetchClasses() async {
    try {
      final response = await SupabaseService.client.from('classes').select();
      classes.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _glassError("Gagal memuat kelas");
    }
  }

  // FETCH SUBJECTS
  Future<void> fetchSubjects() async {
    try {
      final response = await SupabaseService.client.from('subjects').select();
      subjects.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _glassError("Gagal memuat pelajaran");
    }
  }

  // GET SUBJECT NAME
  String _getSubjectNameById(String id) {
    try {
      final m = subjects.firstWhere((s) => s['id'].toString() == id);
      return m['name'] ?? '-';
    } catch (_) {
      return '-';
    }
  }

  // FETCH STUDENTS WITHOUT FINAL GRADES
  Future<void> fetchStudentsWithoutGrades() async {
    if (selectedClassId.value.isEmpty || selectedSubjectId.value.isEmpty) {
      _glassWarning("Pilih kelas & pelajaran terlebih dahulu");
      return;
    }

    isLoading.value = true;

    try {
      final gradeIdsResponse = await SupabaseService.client
          .from('grades_ujian_akhir')
          .select('student_id')
          .eq('subject_id', int.parse(selectedSubjectId.value));

      final gradeIds = (gradeIdsResponse as List)
          .map((e) => e['student_id'])
          .where((id) => id != null)
          .toList();

      final result = await SupabaseService.client
          .from('students_ujian_akhir')
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

  // ───────────────── GLASS SNACKBAR iPHONE ─────────────────

  void _glassError(String msg) => _glass(msg, Colors.redAccent);
  void _glassWarning(String msg) => _glass(msg, Colors.amberAccent);
  void _glassSuccess(String msg) => _glass(msg, Colors.greenAccent);

  void _glass(String message, Color color) {
    Get.rawSnackbar(
      messageText: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(milliseconds: 900),
      animationDuration: const Duration(milliseconds: 400),
      borderRadius: 20,
      overlayBlur: 2,
      overlayColor: Colors.black.withOpacity(0.1),
    );
  }

  // ───────────────── UI iPHONE ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionCard([
                _label("Kelas"),
                Obx(
                  () => _iosDropdown(
                    items: classes,
                    selected: selectedClassId.value,
                    onChanged: (v) => selectedClassId.value = v ?? "",
                  ),
                ),
              ]),

              _sectionCard([
                _label("Mata Pelajaran"),
                Obx(
                  () => _iosDropdown(
                    items: subjects,
                    selected: selectedSubjectId.value,
                    onChanged: (v) => selectedSubjectId.value = v ?? "",
                  ),
                ),
              ]),

              const SizedBox(height: 14),

              _iosButton(
                label: "Cari Siswa",
                onTap: fetchStudentsWithoutGrades,
              ),

              const SizedBox(height: 10),

              // Student List
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
                          s['name'] ?? "(Tanpa Nama)",
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
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Pelajaran: ${_getSubjectNameById(selectedSubjectId.value)}",
                          style: GoogleFonts.poppins(
                            color: Colors.black54,
                            fontSize: 14,
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

  // ───────────────── HELPER WIDGETS ─────────────────

  Widget _sectionCard(List<Widget> children) {
    return Container(
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
