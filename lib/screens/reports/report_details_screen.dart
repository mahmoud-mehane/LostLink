import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/lost_found_report.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/report_repository.dart';

class ReportDetailsScreen extends ConsumerStatefulWidget {
  const ReportDetailsScreen({super.key, required this.report});

  final LostFoundReport report;

  @override
  ConsumerState<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends ConsumerState<ReportDetailsScreen> {
  late LostFoundReport _report;
  late ReportStatus _selectedStatus;
  var _isUpdating = false;
  var _changed = false;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _selectedStatus = _report.status;
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == _report.status) return;
    setState(() => _isUpdating = true);
    try {
      await ref.read(reportRepositoryProvider).updateReportStatus(
            type: _report.type,
            reportId: _report.id,
            status: _selectedStatus,
          );
      if (!mounted) return;
      setState(() {
        _report = LostFoundReport(
          id: _report.id,
          userId: _report.userId,
          type: _report.type,
          category: _report.category,
          description: _report.description,
          color: _report.color,
          date: _report.date,
          time: _report.time,
          location: _report.location,
          imageUrl: _report.imageUrl,
          status: _selectedStatus,
          createdAt: _report.createdAt,
        );
        _changed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report status updated.')),
      );
    } on ReportFailure catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('We could not update this report. Please try again.');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final location = _report.location;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_changed),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
              _DetailRow(label: 'Type', value: _report.type == ReportType.lost ? 'Lost' : 'Found'),
              _DetailRow(label: 'Category', value: _report.category.firestoreValue),
              _DetailRow(label: 'Description', value: _report.description),
              _DetailRow(label: 'Color', value: _report.color),
              _DetailRow(label: 'Date', value: _formatDate(_report.date)),
              _DetailRow(label: 'Approximate time', value: _report.time),
              _DetailRow(label: 'Location description', value: location?.description ?? 'Not provided'),
              if (location?.latitude != null || location?.longitude != null)
                _DetailRow(
                  label: 'Coordinates',
                  value: '${location?.latitude ?? '-'}, ${location?.longitude ?? '-'}',
                ),
              _DetailRow(label: 'Image URL', value: _report.imageUrl ?? 'Not provided'),
              _DetailRow(label: 'Status', value: _report.status.firestoreValue),
              const SizedBox(height: 24),
              DropdownButtonFormField<ReportStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Update status',
                  border: OutlineInputBorder(),
                ),
                items: ReportStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.firestoreValue),
                      ),
                    )
                    .toList(),
                onChanged: _isUpdating
                    ? null
                    : (status) => setState(() => _selectedStatus = status!),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isUpdating ? null : _updateStatus,
                child: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save status'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
