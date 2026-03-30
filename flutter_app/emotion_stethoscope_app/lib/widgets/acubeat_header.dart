import 'package:flutter/material.dart';

class AcuBeatHeader extends StatelessWidget {
  const AcuBeatHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          // Black background
          Container(color: Colors.black),

          // Red circle pattern matching the PDF UI
          ..._circles(),

          // Logo card centered
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.red.shade700, width: 2),
                    ),
                    child: Icon(
                      Icons.monitor_heart_rounded,
                      color: Colors.red.shade700,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'AcuBeat',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _circles() {
    final positions = [
      const Offset(-45, -45),
      const Offset(40, -50),
      const Offset(-50, 70),
      const Offset(10, 130),
      const Offset(290, -45),
      const Offset(340, 50),
      const Offset(275, 130),
      const Offset(355, 160),
    ];

    return positions.map((pos) {
      return Positioned(
        left: pos.dx,
        top: pos.dy,
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.82),
          ),
        ),
      );
    }).toList();
  }
}