import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lost_found_report.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'reports/create_report_screen.dart';
import 'reports/my_reports_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.userEmail});

  final String? userEmail;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authServiceProvider).logout();
    } on AuthFailure catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LostLink'),
        actions: [IconButton(onPressed: () => _logout(context, ref), tooltip: 'Logout', icon: const Icon(Icons.logout))],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, size: 56),
              const SizedBox(height: 16),
              const Text('You are signed in.', style: TextStyle(fontSize: 20)),
              if (userEmail != null) ...[const SizedBox(height: 8), Text(userEmail!)],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openCreateReport(context, ReportType.lost),
                  icon: const Icon(Icons.search_off),
                  label: const Text('Report Lost'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openCreateReport(context, ReportType.found),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Report Found'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const MyReportsScreen()),
                  ),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('My Reports'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCreateReport(BuildContext context, ReportType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateReportScreen(initialType: type),
      ),
    );
  }
}
