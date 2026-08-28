import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/lost_found_report.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/report_repository.dart';
import 'report_details_screen.dart';

class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  List<LostFoundReport>? _reports;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _reports = null;
      _errorMessage = null;
    });
    try {
      final reports = await ref.read(reportRepositoryProvider).getCurrentUserReports();
      if (mounted) setState(() => _reports = reports);
    } on ReportFailure catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'We could not load your reports. Please try again.');
      }
    }
  }

  Future<void> _openDetails(LostFoundReport report) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => ReportDetailsScreen(report: report)),
    );
    if (changed == true && mounted) await _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    final reports = _reports;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My reports'),
        actions: [IconButton(onPressed: _loadReports, tooltip: 'Refresh', icon: const Icon(Icons.refresh))],
      ),
      body: reports == null
          ? _errorMessage == null
              ? const Center(child: CircularProgressIndicator())
              : _ErrorState(message: _errorMessage!, onRetry: _loadReports)
          : reports.isEmpty
              ? const Center(child: Text('You have not created any reports yet.'))
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return Card(
                        child: ListTile(
                          onTap: () => _openDetails(report),
                          leading: Icon(
                            report.type == ReportType.lost
                                ? Icons.search_off
                                : Icons.inventory_2_outlined,
                          ),
                          title: Text('${_typeLabel(report.type)} - ${report.category.firestoreValue}'),
                          subtitle: Text(
                            '${report.description}\n${report.color} - ${_formatDate(report.date)}'
                            '${report.location?.description == null ? '' : '\n${report.location!.description}'}',
                          ),
                          isThreeLine: report.location?.description != null,
                          trailing: Chip(label: Text(report.status.firestoreValue)),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

String _typeLabel(ReportType type) => type == ReportType.lost ? 'Lost' : 'Found';

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
