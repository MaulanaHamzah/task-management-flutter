import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/task.dart';
import 'task_list_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  int _currentIndex = 0;
  String _userName  = '';

  int _total   = 0;
  int _selesai = 0;
  int _proses  = 0;
  int _belum   = 0;
  int _rendah  = 0;
  int _sedang  = 0;
  int _tinggi  = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? 'User';

    final tasks = await _apiService.getTasks();

    setState(() {
      _total   = tasks.length;
      _selesai = tasks.where((t) => t.status == 'selesai').length;
      _proses  = tasks.where((t) => t.status == 'sedang_dikerjakan').length;
      _belum   = tasks.where((t) => t.status == 'belum_dikerjakan').length;
      _rendah  = tasks.where((t) => t.priority == 'rendah').length;
      _sedang  = tasks.where((t) => t.priority == 'sedang').length;
      _tinggi  = tasks.where((t) => t.priority == 'tinggi').length;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    // Tampilkan dialog konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.logout, color: Color(0xFFDC2626), size: 48),
            SizedBox(height: 8),
            Text('Keluar dari Aplikasi?', textAlign: TextAlign.center),
          ],
        ),
        content: const Text(
          'Apakah anda yakin ingin keluar? Anda perlu login kembali untuk mengakses aplikasi.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF2563EB)),
              SizedBox(height: 16),
              Text(
                'Sedang keluar...',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    await _apiService.logout();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.task_alt, color: Colors.white),
            SizedBox(width: 8),
            Text('Task Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildDashboard() : const TaskListScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF2563EB),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Tugas'),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Halo,', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(
                        _userName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistik
            const Text('Statistik Tugas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _statCard('Total Tugas', _total, const Color(0xFF2563EB), Icons.assignment),
                _statCard('Selesai', _selesai, const Color(0xFF16A34A), Icons.check_circle),
                _statCard('Sedang Dikerjakan', _proses, const Color(0xFFD97706), Icons.pending),
                _statCard('Belum Dikerjakan', _belum, const Color(0xFFDC2626), Icons.cancel),
              ],
            ),
            const SizedBox(height: 24),

            // Pie Chart Status
            const Text('Distribusi Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: _total > 0
                  ? Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: CustomPaint(
                            painter: PieChartPainter(
                              values: [_belum.toDouble(), _proses.toDouble(), _selesai.toDouble()],
                              colors: [const Color(0xFFEF4444), const Color(0xFFF59E0B), const Color(0xFF22C55E)],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('$_total', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _legendItem('Belum Dikerjakan', _belum, const Color(0xFFEF4444)),
                        _legendItem('Sedang Dikerjakan', _proses, const Color(0xFFF59E0B)),
                        _legendItem('Selesai', _selesai, const Color(0xFF22C55E)),
                      ],
                    )
                  : const Center(child: Text('Belum ada tugas', style: TextStyle(color: Colors.grey))),
            ),
            const SizedBox(height: 24),

            // Pie Chart Prioritas
            const Text('Distribusi Prioritas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: _total > 0
                  ? Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: CustomPaint(
                            painter: PieChartPainter(
                              values: [_rendah.toDouble(), _sedang.toDouble(), _tinggi.toDouble()],
                              colors: [const Color(0xFF9CA3AF), const Color(0xFF60A5FA), const Color(0xFFEF4444)],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('$_total', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  const Text('Total', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _legendItem('Rendah', _rendah, const Color(0xFF9CA3AF)),
                        _legendItem('Sedang', _sedang, const Color(0xFF60A5FA)),
                        _legendItem('Tinggi', _tinggi, const Color(0xFFEF4444)),
                      ],
                    )
                  : const Center(child: Text('Belum ada tugas', style: TextStyle(color: Colors.grey))),
            ),
            const SizedBox(height: 24),

            // Tombol Tambah Tugas
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _currentIndex = 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.list_alt, color: Colors.white),
                label: const Text('Lihat Semua Tugas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, Color color, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      border: Border(left: BorderSide(color: color, width: 4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

  Widget _legendItem(String label, int value, Color color) {
    final pct = _total > 0 ? (value / _total * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text('$pct%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text('($value)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

// Pie Chart Painter
class PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  PieChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total  = values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 - 16 : size.height / 2 - 16;
    double startAngle = -3.14159 / 2;

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweepAngle = (values[i] / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}