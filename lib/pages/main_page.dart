import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'no_grade_page.dart';
import 'final_exam_page.dart';
import 'no_final_grade_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    NoGradePage(),
    FinalExamPage(),
    NoFinalGradePage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // 🔥 iOS-style nav item
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool active = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withOpacity(0.30)
              : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(active ? 0.45 : 0.20),
            width: 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? Colors.white : Colors.white70, size: 22),
            if (active) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),

      // 🔥 Glass iOS Bottom Navigation
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: Icons.calendar_month_rounded,
                    label: "Kuartal",
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.warning_amber_rounded,
                    label: "Tanpa Kuartal",
                    index: 1,
                  ),
                  _buildNavItem(
                    icon: Icons.school_rounded,
                    label: "Ujian",
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Icons.error_outline_rounded,
                    label: "Tanpa Ujian",
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      backgroundColor: const Color(0xFF0F0F0F),
    );
  }
}
