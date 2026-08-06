import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/attendance_repository.dart';

/// Lets an employee flag a problem with one of their own attendance records.
///
/// Pops `true` once the request is queued. Nothing on this side changes as a
/// result — the backend has no endpoint for an employee to list their own
/// requests, so there is no queue to show them afterwards.
class RequestCorrectionScreen extends StatefulWidget {
  const RequestCorrectionScreen({super.key, this.initialDate});

  /// Prefilled when the user opened this from a history row, so the common
  /// path can't pick a date that has no record behind it.
  final DateTime? initialDate;

  @override
  State<RequestCorrectionScreen> createState() => _RequestCorrectionScreenState();
}

class _RequestCorrectionScreenState extends State<RequestCorrectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _date;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      // Only days that can already have a record: today back through a year.
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      setState(() => _error = 'Choose the date you want corrected.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<AttendanceRepository>().submitCorrection(
            date: DateFormat('yyyy-MM-dd').format(_date!),
            reason: _reasonController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      // A 404 here means the date has no attendance record, which reads as a
      // dead end unless we say what to do instead.
      setState(() => _error = e.statusCode == 404
          ? '${e.message}. A correction can only be raised against a day you '
              'already have a record for — ask your manager to add the day first.'
          : e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Request a correction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date'),
                child: Text(
                  _date == null ? 'Select date' : dateFormat.format(_date!),
                  style: TextStyle(
                    color: _date == null
                        ? AppColors.textMuted
                        : AppColors.primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Must be a day you already have an attendance record for.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: "What's wrong?",
                hintText: 'e.g. I clocked out at 6pm but the record shows 4pm.',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Explain what needs correcting.'
                  : null,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'This queues a note for your manager to review — it does not '
                'change the recorded times on its own.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.accentOrange,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit request'),
            ),
          ],
        ),
      ),
    );
  }
}
