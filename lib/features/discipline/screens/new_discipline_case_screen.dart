import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../employees/data/employee_models.dart';
import '../data/discipline_repository.dart';

const _categories = [
  'ABSENTEEISM',
  'MISCONDUCT',
  'INSUBORDINATION',
  'FRAUD',
  'NEGLIGENCE',
  'POLICY_VIOLATION',
];

/// `SALARY_DEDUCTION` needs a payroll-cycle id and is left off this list —
/// no cycle picker in this narrow mobile slice (plan.txt Tier B).
const _actionTypes = ['QUERY', 'VERBAL_WARNING', 'WRITTEN_WARNING', 'SUSPENSION', 'DISMISSAL'];

/// Pops `true` on success so [DisciplineCasesScreen] knows to refresh.
/// Chains up to three backend calls: create the case, optionally record an
/// initial action, and — only if a photo was captured — attach it to that
/// action (see [DisciplineRepository] for why a bare case has no action id
/// to upload a document against).
class NewDisciplineCaseScreen extends StatefulWidget {
  const NewDisciplineCaseScreen({super.key, required this.employee});

  final EmployeeResponse employee;

  @override
  State<NewDisciplineCaseScreen> createState() => _NewDisciplineCaseScreenState();
}

class _NewDisciplineCaseScreenState extends State<NewDisciplineCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = _categories.first;
  DateTime _incidentDate = DateTime.now();
  bool _recordAction = false;
  String _actionType = _actionTypes.first;
  DateTime _actionDate = DateTime.now();
  XFile? _photo;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickIncidentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _incidentDate = picked);
  }

  Future<void> _pickActionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _actionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _actionDate = picked);
  }

  Future<void> _capturePhoto(ImageSource source) async {
    final photo = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (photo != null) setState(() => _photo = photo);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    final dateFormat = DateFormat('yyyy-MM-dd');
    final repository = context.read<DisciplineRepository>();
    try {
      final createdCase = await repository.createCase(
        employeeId: widget.employee.id,
        category: _category,
        description: _descriptionController.text.trim(),
        incidentDate: dateFormat.format(_incidentDate),
      );

      if (_recordAction) {
        final action = await repository.createAction(
          caseId: createdCase.id,
          actionType: _actionType,
          actionDate: dateFormat.format(_actionDate),
          notes: _notesController.text.trim(),
        );
        if (_photo != null) {
          await repository.uploadDocument(action.id, _photo!.path);
        }
      }

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
      appBar: AppBar(title: Text('New case · ${widget.employee.fullName}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Description is required.' : null,
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'Incident date',
              value: dateFormat.format(_incidentDate),
              onTap: _pickIncidentDate,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Record an action now'),
              value: _recordAction,
              onChanged: (value) => setState(() => _recordAction = value),
            ),
            if (_recordAction) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _actionType,
                decoration: const InputDecoration(labelText: 'Action type'),
                items: _actionTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (value) => setState(() => _actionType = value!),
              ),
              const SizedBox(height: 16),
              _DateField(
                label: 'Action date',
                value: dateFormat.format(_actionDate),
                onTap: _pickActionDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 16),
              if (_photo != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_photo!.path), height: 160, fit: BoxFit.cover),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _capturePhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(_photo == null ? 'Take photo' : 'Retake'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _capturePhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
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
                  : const Text('Save case'),
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
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value, style: const TextStyle(color: AppColors.primaryGreen)),
      ),
    );
  }
}
