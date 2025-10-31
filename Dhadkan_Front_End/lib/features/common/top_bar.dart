import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final String title;

  const TopBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.center,
      // mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          children: [
            // SizedBox(width: 20),
            Text(title,
                style: const TextStyle().copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white))
          ],
        )
      ],
    );
  }
}
