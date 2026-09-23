import 'package:flutter/material.dart';

class GreetingHeader extends StatelessWidget {
  final String userName;
  const GreetingHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, $userName',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 2),
            const Text('Flunds',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.notifications_none, color: Colors.black54),
        ),
      ],
    );
  }
}