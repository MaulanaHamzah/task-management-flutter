import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/task.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _apiService         = ApiService();
  final _titleController    = TextEditingController();
  final _descController     = TextEditingController();
  String _priority          = 'sedang';
  String _status            = 'belum_dikerjakan';
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _isLoading           = false;
  String? _errorMessage;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _titleController.text = widget.task!.title;
      _descController.text  = widget.task!.description;
      _priority             = widget.task!.priority;
      _status               = widget.task!.status;
      _startDate            = DateTime.parse(widget.task!.startDate);
      _dueDate              = DateTime.parse(widget.task!.dueDate);
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_dueDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_dueDate != null && _dueDate!.isBefore(picked)) _dueDate = null;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().length < 5) {
      setState(() => _errorMessage = 'Judul minimal 5 karakter.');
      return;
    }
    if (_descController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Deskripsi wajib diisi.');
      return;
    }
    if (_startDate == null) {
      setState(() => _errorMessage = 'Tanggal mulai wajib dipilih.');
      return;
    }
    if (_dueDate == null) {
      setState(() => _errorMessage = 'Deadline wajib dipilih.');
      return;
    }

    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    // Loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF2563EB)),
            const SizedBox(height: 16),
            Text(
              _isEdit ? 'Menyimpan perubahan...' : 'Menambahkan tugas...',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1000));

    final data = {
      'title':       _titleController.text.trim(),
      'description': _descController.text.trim(),
      'start_date':  _startDate!.toIso8601String().split('T')[0],
      'due_date':    _dueDate!.toIso8601String().split('T')[0],
      'priority':    _priority,
      'status':      _status,
    };

    final result = _isEdit
        ? await _apiService.updateTask(widget.task!.id, data)
        : await _apiService.createTask(data);

    if (mounted) Navigator.pop(context);

    if (result['status'] == 200 || result['status'] == 201) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Tugas berhasil diperbarui!' : 'Tugas berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _isLoading    = false;
        _errorMessage = 'Gagal menyimpan tugas. Coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        title: Text(
          _isEdit ? 'Edit Tugas' : 'Tambah Tugas',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Judul
              _label('Judul *'),
              TextField(
                controller: _titleController,
                decoration: _inputDecoration('Minimal 5 karakter', Icons.title),
              ),
              const SizedBox(height: 16),

              // Deskripsi
              _label('Deskripsi *'),
              TextField(
                controller: _descController,
                maxLines: 4,
                decoration: _inputDecoration('Deskripsikan tugas...', Icons.description),
              ),
              const SizedBox(height: 16),

              // Tanggal
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Tanggal Mulai *'),
                        InkWell(
                          onTap: () => _pickDate(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFFF9FAFB),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _startDate != null
                                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                      : 'Pilih tanggal',
                                  style: TextStyle(
                                    color: _startDate != null ? Colors.black87 : Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Deadline *'),
                        InkWell(
                          onTap: () => _pickDate(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFFF9FAFB),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _dueDate != null
                                      ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                      : 'Pilih tanggal',
                                  style: TextStyle(
                                    color: _dueDate != null ? Colors.black87 : Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Prioritas
              _label('Prioritas *'),
              _dropdownField(
                value: _priority,
                items: const [
                  DropdownMenuItem(value: 'rendah', child: Text('Rendah')),
                  DropdownMenuItem(value: 'sedang', child: Text('Sedang')),
                  DropdownMenuItem(value: 'tinggi', child: Text('Tinggi')),
                ],
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 16),

              // Status
              _label('Status *'),
              _dropdownField(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'belum_dikerjakan', child: Text('Belum Dikerjakan')),
                  DropdownMenuItem(value: 'sedang_dikerjakan', child: Text('Sedang Dikerjakan')),
                  DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 24),

              // Tombol Submit
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEdit ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    _isEdit ? 'Update Tugas' : 'Simpan Tugas',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF374151))),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
    );
  }

  Widget _dropdownField({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFF9FAFB),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}