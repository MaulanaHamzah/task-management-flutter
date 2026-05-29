class Task {
  final int id;
  final String title;
  final String description;
  final String startDate;
  final String dueDate;
  final String priority;
  final String status;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.dueDate,
    required this.priority,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id:          json['id'],
      title:       json['title'],
      description: json['description'],
      startDate:   json['start_date'],
      dueDate:     json['due_date'],
      priority:    json['priority'],
      status:      json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title':       title,
      'description': description,
      'start_date':  startDate,
      'due_date':    dueDate,
      'priority':    priority,
      'status':      status,
    };
  }

  String get statusLabel {
    switch (status) {
      case 'belum_dikerjakan':  return 'Belum Dikerjakan';
      case 'sedang_dikerjakan': return 'Sedang Dikerjakan';
      case 'selesai':           return 'Selesai';
      default:                  return '-';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'rendah': return 'Rendah';
      case 'sedang': return 'Sedang';
      case 'tinggi': return 'Tinggi';
      default:       return '-';
    }
  }
}