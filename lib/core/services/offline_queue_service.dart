import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum OperationType {
  createMember,
  createPayment,
  markAttendance,
  updateMember,
  updateStaff,
  createExpense,
  unknown;

  String get value => name;

  static OperationType fromString(String s) {
    return OperationType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => OperationType.unknown,
    );
  }
}

enum OperationStatus { pending, processing, completed, failed }

class QueueOperation {
  final String id;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  OperationStatus status;

  QueueOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.status = OperationStatus.pending,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
      };

  factory QueueOperation.fromJson(Map<String, dynamic> json) => QueueOperation(
        id: json['id'] as String,
        type: OperationType.fromString(json['type'] as String),
        data: Map<String, dynamic>.from(json['data'] as Map),
        timestamp: DateTime.parse(json['timestamp'] as String),
        status: OperationStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => OperationStatus.pending,
        ),
      );
}

typedef OperationHandler = Future<bool> Function(QueueOperation operation);

class OfflineQueueService {
  static const String _queueKey = 'offline_queue';
  static OfflineQueueService? _instance;

  final List<QueueOperation> _queue = [];
  final FlutterSecureStorage _storage;
  OperationHandler? _handler;
  bool _isProcessing = false;

  OfflineQueueService._(this._storage);

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static Future<OfflineQueueService> getInstance() async {
    if (_instance != null) return _instance!;
    const storage = FlutterSecureStorage(
      aOptions: _androidOptions,
    );
    _instance = OfflineQueueService._(storage);
    await _instance!._loadQueue();
    return _instance!;
  }

  void setHandler(OperationHandler handler) {
    _handler = handler;
  }

  Future<void> enqueue(OperationType type, Map<String, dynamic> data) async {
    final operation = QueueOperation(
      id: '${DateTime.now().millisecondsSinceEpoch}_${type.value}',
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );
    _queue.add(operation);
    await _persistQueue();
  }

  QueueOperation? dequeue() {
    if (_queue.isEmpty) return null;
    final operation = _queue.removeAt(0);
    _persistQueue();
    return operation;
  }

  Future<void> processQueue() async {
    if (_isProcessing || _handler == null) return;
    _isProcessing = true;

    try {
      final snapshot = List<QueueOperation>.from(_queue);
      for (final operation in snapshot) {
        if (!_queue.contains(operation)) continue;

        operation.status = OperationStatus.processing;
        await _persistQueue();

        try {
          final success = await _handler!(operation);
          if (success) {
            operation.status = OperationStatus.completed;
            _removeOperation(operation.id);
          } else {
            operation.status = OperationStatus.failed;
            await _persistQueue();
          }
        } catch (e) {
          final errorStr = e.toString().toLowerCase();
          final isNetworkError = errorStr.contains('network') ||
              errorStr.contains('socket') ||
              errorStr.contains('timeout') ||
              errorStr.contains('connection') ||
              errorStr.contains('host') ||
              errorStr.contains('dns') ||
              errorStr.contains('handshake');
          if (isNetworkError) {
            operation.status = OperationStatus.pending;
            await _persistQueue();
            break;
          }
          operation.status = OperationStatus.failed;
          await _persistQueue();
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  int getQueueLength() => _queue.length;

  List<QueueOperation> get pendingOperations =>
      _queue.where((o) => o.status == OperationStatus.pending).toList();

  Future<void> clear() async {
    _queue.clear();
    await _storage.delete(key: _queueKey);
  }

  Future<void> _removeOperation(String id) async {
    _queue.removeWhere((o) => o.id == id);
    await _persistQueue();
  }

  Future<void> _loadQueue() async {
    final raw = await _storage.read(key: _queueKey);
    if (raw == null || raw.isEmpty) return;
    final list = jsonDecode(raw) as List;
    _queue.addAll(list.map((e) => QueueOperation.fromJson(e as Map<String, dynamic>)));
  }

  Future<void> _persistQueue() async {
    final list = _queue.map((o) => o.toJson()).toList();
    await _storage.write(key: _queueKey, value: jsonEncode(list));
  }
}
