import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value == null || value.isEmpty) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    final gymId = ref.read(authProvider).gymId;
    if (gymId == null) {
      _showError('Gym not found');
      return;
    }

    try {
      final member = await _lookupMember(gymId, value);
      if (member == null) {
        _showError('No member found for code: $value');
        return;
      }

      final repo = ref.read(attendanceRepositoryProvider);
      await repo.checkIn(gymId, member['id'] as String);
      final name = member['name'] as String;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name checked in successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(todayAttendanceProvider(gymId));
        context.pop();
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>?> _lookupMember(
      String gymId, String code) async {
    final client = Supabase.instance.client;

    Map<String, dynamic>? member = await client
        .from('members')
        .select('id, name, phone')
        .eq('gym_id', gymId)
        .eq('id', code)
        .maybeSingle();

    if (member != null) return member;

    member = await client
        .from('members')
        .select('id, name, phone')
        .eq('gym_id', gymId)
        .eq('phone', code)
        .maybeSingle();

    return member;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 28),
                      onPressed: () => context.pop(),
                    ),
                    StatefulBuilder(
                      builder: (context, setLocalState) {
                        return IconButton(
                          icon: const Icon(
                            Icons.flash_on_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () =>
                              _controller.toggleTorch(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            ],
          ),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Stack(
              children: [
                // Corner brackets
                Positioned(top: -2, left: -2, child: _cornerBracket(Colors.white, true, true)),
                Positioned(top: -2, right: -2, child: _cornerBracket(Colors.white, true, false)),
                Positioned(bottom: -2, left: -2, child: _cornerBracket(Colors.white, false, true)),
                Positioned(bottom: -2, right: -2, child: _cornerBracket(Colors.white, false, false)),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Point camera at member QR code',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cornerBracket(Color color, bool isTop, bool isLeft) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: color, width: 4) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: color, width: 4) : BorderSide.none,
          left: isLeft ? BorderSide(color: color, width: 4) : BorderSide.none,
          right: !isLeft ? BorderSide(color: color, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}
