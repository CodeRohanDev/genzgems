// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class FaceFilters extends StatefulWidget {
  const FaceFilters({super.key});

  @override
  State<FaceFilters> createState() => _FaceFiltersState();
}

class _FaceFiltersState extends State<FaceFilters> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/face_filter_icon.png"),
            Text(
              "Coming Soon!",
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 35, letterSpacing: 1),
            )
          ],
        ),
      ),
    );
  }
}
