import 'package:flutter/material.dart';

class ElephantLogo extends StatelessWidget {
  final double size;

  const ElephantLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset('assets/logo.png', fit: BoxFit.contain),
    );
  }
}
