import 'package:flutter/material.dart';

/// Stand-in for a nav destination whose feature hasn't been built yet
/// (see plan.txt phased build order) — keeps the app shell honest about
/// what's wired vs. still pending.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title is coming soon.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
