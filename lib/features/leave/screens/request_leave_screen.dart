import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../data/leave_models.dart';
import '../data/leave_repository.dart';

/// Pops `true` when a request is successfully created so [LeaveScreen] knows
/// to refresh balances/history.
class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key, required this.leaveTypes});

  final List<LeaveTypeResponse> leaveTypes;

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _leaveTypeId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isStart ? now.subtract(const Duration(days: 1)) : (_startDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      setState(() => _error = 'Choose a start and end date.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    final dateFormat = DateFormat('yyyy-MM-dd');
    try {
      await context.read<LeaveRepository>().createRequest(
            leaveTypeId: _leaveTypeId!,
            startDate: dateFormat.format(_startDate!),
            endDate: dateFormat.format(_endDate!),
            reason: _reasonController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Request leave')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _leaveTypeId,
              decoration: const InputDecoration(labelText: 'Leave type'),
              items: widget.leaveTypes
                  .map((type) => DropdownMenuItem(value: type.id, child: Text(type.name)))
                  .toList(),
              onChanged: (value) => setState(() => _leaveTypeId = value),
              validator: (value) => value == null ? 'Select a leave type.' : null,
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'Start date',
              value: _startDate == null ? null : dateFormat.format(_startDate!),
              onTap: () => _pickDate(isStart: true),
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'End date',
              value: _endDate == null ? null : dateFormat.format(_endDate!),
              onTap: () => _pickDate(isStart: false),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.accentOrange, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value ?? 'Select date',
          style: TextStyle(color: value == null ? AppColors.textMuted : AppColors.primaryGreen),
        ),
      ),
    );
  }
}
