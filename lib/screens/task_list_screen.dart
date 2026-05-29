import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/task.dart';
import 'task_form_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _apiService    = ApiService();
  final _searchController = TextEditingController();
  List<Task> _tasks    = [];
  List<Task> _filtered = [];
  bool _isLoading      = true;
  String _filterStatus = '';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await _apiService.getTasks();
    setState(() {
      _tasks    = tasks;
      _filtered = tasks;
      _isLoading = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      _filtered = _tasks.where((t) {
        final matchSearch = t.title.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchStatus = _filterStatus.isEmpty || t.status == _filterStatus;
        return matchSearch && matchStatus;
      }).toList();
    });
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tugas?'),
        content: Text('Yakin ingin menghapus "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _apiService.deleteTask(task.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas berhasil dihapus!'), backgroundColor: Colors.green),
      );
      _loadTasks();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'selesai':           return const Color(0xFF16A34A);
      case 'sedang_dikerjakan': return const Color(0xFFD97706);
      default:                  return const Color(0xFFDC2626);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'tinggi': return const Color(0xFFDC2626);
      case 'sedang': return const Color(0xFF2563EB);
      default:       return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        title: const Text('Daftar Tugas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TaskFormScreen()),
              );
              _loadTasks();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilter(),
                  decoration: InputDecoration(
                    hintText: 'Cari judul tugas...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Semua', ''),
                      _filterChip('Belum', 'belum_dikerjakan'),
                      _filterChip('Sedang', 'sedang_dikerjakan'),
                      _filterChip('Selesai', 'selesai'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: _filtered.isEmpty
                        ? const Center(child: Text('Tidak ada tugas ditemukan.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filtered.length,
                            itemBuilder: (_, index) {
                              final task = _filtered[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                                    );
                                    _loadTasks();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                task.title,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _priorityColor(task.priority).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                task.priorityLabel,
                                                style: TextStyle(fontSize: 11, color: _priorityColor(task.priority), fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          task.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${task.startDate} → ${task.dueDate}',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _statusColor(task.status).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                task.statusLabel,
                                                style: TextStyle(fontSize: 11, color: _statusColor(task.status), fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
                                                );
                                                _loadTasks();
                                              },
                                              icon: const Icon(Icons.edit, size: 16, color: Color(0xFFD97706)),
                                              label: const Text('Edit', style: TextStyle(color: Color(0xFFD97706), fontSize: 13)),
                                            ),
                                            TextButton.icon(
                                              onPressed: () => _deleteTask(task),
                                              icon: const Icon(Icons.delete, size: 16, color: Color(0xFFDC2626)),
                                              label: const Text('Hapus', style: TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskFormScreen()),
          );
          _loadTasks();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _filterStatus = value);
          _applyFilter();
        },
        selectedColor: const Color(0xFF2563EB).withOpacity(0.2),
        checkmarkColor: const Color(0xFF2563EB),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}