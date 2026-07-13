import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../services/app_state.dart';
import '../../services/verfication_service.dart';
import '../../models/scan_record.dart';

class ScanScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const ScanScreen({super.key, required this.cameras});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {

  // ── Camera ─────────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isFlashOn = false;

  // ── Scan State ─────────────────────────────────────────────────────────────
  _ScanMode _mode = _ScanMode.idle;
  File? _capturedImage;
  String _statusMessage = 'Choose how to scan your medicine';

  // ── Animation ──────────────────────────────────────────────────────────────
  late AnimationController _animController;
  late Animation<double> _scanLineAnim;

  // ── ImagePicker ────────────────────────────────────────────────────────────
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  MODE 1 — Live Camera
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _startLiveCamera() async {
    // Load cameras lazily (not at app startup) to avoid a blank first frame.
    var cams = widget.cameras;
    if (cams.isEmpty) {
      try {
        cams = await availableCameras();
      } catch (_) {}
    }
    if (cams.isEmpty) {
      _showError('No camera found on this device.');
      return;
    }
    setState(() {
      _mode = _ScanMode.liveCamera;
      _statusMessage = 'Frame the medicine label, then tap capture';
    });
    try {
      _cameraController = CameraController(
        cams[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      _showError('Could not open camera: $e');
      _reset();
    }
  }

  Future<void> _captureFromCamera() async {
    if (_cameraController == null || !_isCameraReady) return;
    try {
      final XFile xFile = await _cameraController!.takePicture();
      await _sendToBackend(File(xFile.path));
    } catch (e) {
      _showError('Failed to capture photo: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  MODE 2 — Take Photo
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _takePhoto() async {
    setState(() => _statusMessage = 'Opening camera...');
    final XFile? xFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (xFile == null) {
      setState(() => _statusMessage = 'Choose how to scan your medicine');
      return;
    }
    await _sendToBackend(File(xFile.path));
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  MODE 3 — Upload from Gallery
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _uploadFromGallery() async {
    setState(() => _statusMessage = 'Opening gallery...');
    final XFile? xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (xFile == null) {
      setState(() => _statusMessage = 'Choose how to scan your medicine');
      return;
    }
    await _sendToBackend(File(xFile.path));
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  Send to Backend
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _sendToBackend(File imageFile) async {
    setState(() {
      _capturedImage = imageFile;
      _mode = _ScanMode.analyzing;
      _statusMessage = 'Checking the TMDA register…';
    });

    // Free-tier backends sleep when idle; the first request has to cold-start.
    // If we're still waiting after a few seconds, explain why so it doesn't
    // look frozen.
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted && _mode == _ScanMode.analyzing) {
        setState(() => _statusMessage =
            'Waking up the server — the first scan can take up to a minute…');
      }
    });

    final record = await VerificationService.verify(imageFile);

    if (!mounted) return;

    if (record != null) {
      // ── Not a medicine image — show guidance, do NOT go to result screen ──
      if (record.status == VerificationStatus.notMedicine) {
        _reset();
        _showNotMedicineDialog();
        return;
      }

      // ✅ Real medicine scan (verified / counterfeit / unknown) → result screen
      context.read<AppState>().addScan(record);
      Navigator.pushReplacementNamed(context, '/result');
      return;
    }

    // ❌ Network / server failure
    final error = VerificationService.lastError ?? 'Verification failed.';
    VerificationService.clearError();
    _showError(error);
    _reset();
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  Not-a-medicine bottom sheet
  // ────────────────────────────────────────────────────────────────────────────
  void _showNotMedicineDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.image_search_rounded,
                color: AppTheme.warning,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'No Medicine Detected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Body
            const Text(
              "The image doesn't appear to be a medicine. "
              'Please scan a medicine package, box, or label. '
              'Try adjusting your camera angle or improving lighting.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Tips
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppTheme.warning.withOpacity(0.25)),
              ),
              child: const Column(
                children: [
                  _TipRow(
                      emoji: '💊',
                      text: 'Point at a medicine box, strip, or bottle'),
                  SizedBox(height: 8),
                  _TipRow(
                      emoji: '💡',
                      text: 'Make sure lighting is bright and even'),
                  SizedBox(height: 8),
                  _TipRow(
                      emoji: '🔍',
                      text:
                          'Hold steady so the label is sharp and clear'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Try again button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  Helpers
  // ────────────────────────────────────────────────────────────────────────────
  void _reset() {
    _cameraController?.dispose();
    _cameraController = null;
    if (mounted) {
      setState(() {
        _mode = _ScanMode.idle;
        _isCameraReady = false;
        _isFlashOn = false;
        _capturedImage = null;
        _statusMessage = 'Choose how to scan your medicine';
      });
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  Build
  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackground(),
          if (_mode == _ScanMode.analyzing)
            Container(color: Colors.black.withOpacity(0.55)),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 12),
                _buildStatusChip(),
                const Spacer(),
                _buildFrame(),
                const Spacer(),
                _buildBottomPanel(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ─────────────────────────────────────────────────────────────
  Widget _buildBackground() {
    if (_mode == _ScanMode.analyzing && _capturedImage != null) {
      return Positioned.fill(
        child: Image.file(_capturedImage!, fit: BoxFit.cover),
      );
    }
    if (_mode == _ScanMode.liveCamera && _isCameraReady) {
      return Positioned.fill(child: CameraPreview(_cameraController!));
    }
    if (_mode == _ScanMode.liveCamera && !_isCameraReady) {
      return const Positioned.fill(
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }
    return Positioned.fill(child: _GridBackground());
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _GlassButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: _mode == _ScanMode.idle
                ? () => Navigator.pop(context)
                : _reset,
          ),
          const SizedBox(width: 14),
          Text(
            'Scan Medicine',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
          ),
          const Spacer(),
          if (_mode == _ScanMode.liveCamera && _isCameraReady)
            _GlassButton(
              icon: _isFlashOn
                  ? Icons.flash_on_rounded
                  : Icons.flash_off_rounded,
              onTap: () async {
                final next = !_isFlashOn;
                await _cameraController
                    ?.setFlashMode(next ? FlashMode.torch : FlashMode.off);
                if (mounted) setState(() => _isFlashOn = next);
              },
            ),
        ],
      ),
    );
  }

  // ── Status Chip ────────────────────────────────────────────────────────────
  Widget _buildStatusChip() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_statusMessage),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // ── Scan Frame ─────────────────────────────────────────────────────────────
  Widget _buildFrame() {
    final frameSize = MediaQuery.of(context).size.width * 0.75;
    final isActive =
        _mode == _ScanMode.liveCamera || _mode == _ScanMode.analyzing;
    final borderColor =
        isActive ? AppTheme.accent : Colors.white.withOpacity(0.5);

    return SizedBox(
      width: frameSize,
      height: frameSize,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(24),
                color: _mode == _ScanMode.analyzing
                    ? Colors.black.withOpacity(0.3)
                    : null,
              ),
              child: _mode == _ScanMode.analyzing
                  ? _AnalyzingOverlay()
                  : null,
            ),
          ),
          if (_mode == _ScanMode.liveCamera && _isCameraReady)
            AnimatedBuilder(
              animation: _scanLineAnim,
              builder: (_, __) => Positioned(
                left: 2,
                right: 2,
                top: _scanLineAnim.value * (frameSize - 6),
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Colors.transparent,
                      AppTheme.accent,
                      Colors.transparent,
                    ]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          _CornerDecor(color: borderColor, pos: _Pos.tl),
          _CornerDecor(color: borderColor, pos: _Pos.tr),
          _CornerDecor(color: borderColor, pos: _Pos.bl),
          _CornerDecor(color: borderColor, pos: _Pos.br),
        ],
      ),
    );
  }

  // ── Bottom Panel ───────────────────────────────────────────────────────────
  Widget _buildBottomPanel() {
    switch (_mode) {
      case _ScanMode.idle:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _OptionCard(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Live Scan',
                      sublabel: 'Use camera',
                      color: AppTheme.primary,
                      onTap: _startLiveCamera,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OptionCard(
                      icon: Icons.camera_alt_rounded,
                      label: 'Take Photo',
                      sublabel: 'Capture image',
                      color: AppTheme.info,
                      onTap: _takePhoto,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OptionCard(
                      icon: Icons.photo_library_rounded,
                      label: 'Upload',
                      sublabel: 'From gallery',
                      color: const Color(0xFF9B59B6),
                      onTap: _uploadFromGallery,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _showTips,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tips_and_updates_rounded,
                      color: Colors.white.withOpacity(0.6), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Photo tips for best results',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case _ScanMode.liveCamera:
        return Column(
          children: [
            if (!_isCameraReady)
              Text('Initializing camera...',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 13)),
            if (_isCameraReady) ...[
              GestureDetector(
                onTap: _captureFromCamera,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.primaryShadow,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 3),
                  ),
                  child: const Icon(Icons.camera_rounded,
                      color: Colors.white, size: 34),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap to capture',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _reset,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );

      case _ScanMode.analyzing:
        return Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation(AppTheme.accent),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Checking the TMDA register...',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Please wait, this may take a few seconds',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
          ],
        );
    }
  }

  // ── Tips Modal ─────────────────────────────────────────────────────────────
  void _showTips() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('📸 Tips for Best Results',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            ...[
              ['📦', 'Show the full medicine packaging or label'],
              ['💡', 'Ensure good lighting — avoid dark or dim areas'],
              ['🔍', 'Make sure barcodes and text are sharp and in focus'],
              ['📐', 'Hold the camera parallel to the label, not at an angle'],
              ['🚫', 'Avoid glare, reflections, and shadows on packaging'],
              ['🔄', 'If scan fails, try from a different angle or distance'],
            ].map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tip[0], style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(tip[1],
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: AppTheme.textPrimary)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────────
//  Enums & Sub-widgets
// ────────────────────────────────────────────────────────────────────────────────

enum _ScanMode { idle, liveCamera, analyzing }

// ── Tip Row ────────────────────────────────────────────────────────────────────
class _TipRow extends StatelessWidget {
  final String emoji;
  final String text;
  const _TipRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Option Card ────────────────────────────────────────────────────────────────
class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Analyzing Overlay ──────────────────────────────────────────────────────────
class _AnalyzingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppTheme.accent),
              ),
              SizedBox(height: 16),
              Text(
                'Reading label...',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Glass Button ───────────────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ── Grid Background ────────────────────────────────────────────────────────────
class _GridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.white.withOpacity(0.03), width: 0.5),
        ),
      ),
      itemCount: 200,
    );
  }
}

// ── Corner Decoration ──────────────────────────────────────────────────────────
enum _Pos { tl, tr, bl, br }

class _CornerDecor extends StatelessWidget {
  final Color color;
  final _Pos pos;
  const _CornerDecor({required this.color, required this.pos});

  @override
  Widget build(BuildContext context) {
    const cs = 28.0;
    return Positioned(
      top: (pos == _Pos.tl || pos == _Pos.tr) ? 0 : null,
      bottom: (pos == _Pos.bl || pos == _Pos.br) ? 0 : null,
      left: (pos == _Pos.tl || pos == _Pos.bl) ? 0 : null,
      right: (pos == _Pos.tr || pos == _Pos.br) ? 0 : null,
      child: SizedBox(
        width: cs,
        height: cs,
        child: CustomPaint(
          painter: _CornerPainter(color: color, pos: pos),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final _Pos pos;
  _CornerPainter({required this.color, required this.pos});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final l = size.width;
    switch (pos) {
      case _Pos.tl:
        canvas.drawLine(Offset(0, l), Offset.zero, p);
        canvas.drawLine(Offset.zero, Offset(l, 0), p);
        break;
      case _Pos.tr:
        canvas.drawLine(const Offset(0, 0), Offset(l, 0), p);
        canvas.drawLine(Offset(l, 0), Offset(l, l), p);
        break;
      case _Pos.bl:
        canvas.drawLine(Offset.zero, Offset(0, l), p);
        canvas.drawLine(Offset(0, l), Offset(l, l), p);
        break;
      case _Pos.br:
        canvas.drawLine(Offset(l, 0), Offset(l, l), p);
        canvas.drawLine(Offset(0, l), Offset(l, l), p);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}