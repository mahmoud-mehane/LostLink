import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/lost_found_report.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/report_repository.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key, required this.initialType});

  final ReportType initialType;

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _colorController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();

  late ReportType _type;
  ReportCategory? _category;
  DateTime? _date;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _date == null) {
      if (_date == null) setState(() {});
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repository = ref.read(reportRepositoryProvider);
      final locationDescription = _locationController.text.trim();
      final location = locationDescription.isEmpty
          ? null
          : ReportLocation(description: locationDescription);

      if (_type == ReportType.lost) {
        await repository.createLostReport(
          category: _category!,
          description: _descriptionController.text.trim(),
          color: _colorController.text.trim(),
          date: _date!,
          time: _timeController.text.trim(),
          location: location,
        );
      } else {
        await repository.createFoundReport(
          category: _category!,
          description: _descriptionController.text.trim(),
          color: _colorController.text.trim(),
          date: _date!,
          time: _timeController.text.trim(),
          location: location,
        );
      }

      if (!mounted) return;
      _formKey.currentState!.reset();
      _descriptionController.clear();
      _colorController.clear();
      _timeController.clear();
      _locationController.clear();
      setState(() {
        _type = widget.initialType;
        _category = null;
        _date = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your report was created successfully.')),
      );
    } on ReportFailure catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('We could not create your report. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
    if (selectedDate != null && mounted) setState(() => _date = selectedDate);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _colorController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create report')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<ReportType>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Report type',
                        border: OutlineInputBorder(),
                      ),
                      items: ReportType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type == ReportType.lost ? 'Lost item' : 'Found item'),
                            ),
                          )
                          .toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (type) => setState(() => _type = type!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ReportCategory>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: ReportCategory.values
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.firestoreValue),
                            ),
                          )
                          .toList(),
                      validator: (category) => category == null ? 'Select a category.' : null,
                      onChanged: _isSubmitting
                          ? null
                          : (category) => setState(() => _category = category),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !_isSubmitting,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Enter a description.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _colorController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Enter a color.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    FormField<DateTime>(
                      validator: (_) => _date == null ? 'Select the date.' : null,
                      builder: (field) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : _selectDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _date == null
                                  ? 'Select date'
                                  : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                          if (field.hasError)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 4),
                              child: Text(
                                field.errorText!,
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _timeController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Approximate time',
                        hintText: 'For example: Around 5 PM',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Enter an approximate time.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Location description (optional)',
                        hintText: 'For example: Near the university gate',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit report'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
