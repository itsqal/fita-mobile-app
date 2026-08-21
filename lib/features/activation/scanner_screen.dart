import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/format/msisdn.dart';
import '../../core/theme/brand.dart';

/// The full-screen barcode scanner.
///
/// Pops with the MSISDN already normalised to `62` form — §7 rule 3 says to
/// convert once, at the scan boundary, and this is that boundary.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    // The box carries several codes; the MSISDN is a 1-D barcode.
    formats: const [
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.ean13,
      BarcodeFormat.codabar,
    ],
  );

  bool _handled = false;
  String? _rejected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;

      final normalised = Msisdn.normalise(raw);
      if (normalised != null) {
        _handled = true;
        Navigator.of(context).pop(normalised);
        return;
      }
      // A readable code that is not a phone number — the box has several.
      // Say so rather than silently ignoring it.
      if (mounted && _rejected != raw) {
        setState(() => _rejected = raw);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          const _ScanWindow(),

          // Top controls.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundControl(
                    icon: Icons.close,
                    tooltip: 'Tutup',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, state, _) {
                      final on = state.torchState == TorchState.on;
                      return _RoundControl(
                        icon: on ? Icons.flash_on : Icons.flash_off,
                        tooltip: on ? 'Matikan lampu' : 'Nyalakan lampu',
                        onTap: () => _controller.toggleTorch(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Hint pill and bottom controls.
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_rejected != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _Pill(
                          text: 'Kode ini bukan nomor MSISDN. '
                              'Arahkan ke barcode nomor pada kotak.',
                          background: Brand.danger.withValues(alpha: 0.9),
                        ),
                      ),
                    const _Pill(
                      text: 'Posisikan garis merah pada barcode',
                      background: Color(0xCC1F4E4A),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _RoundControl(
                          icon: Icons.photo_library_outlined,
                          tooltip: 'Pilih dari galeri',
                          size: 46,
                          onTap: _pickFromGallery,
                        ),
                        _Shutter(onTap: () {}),
                        _RoundControl(
                          icon: Icons.cameraswitch_outlined,
                          tooltip: 'Ganti kamera',
                          size: 46,
                          onTap: () => _controller.switchCamera(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The mockup shows a gallery picker, but choosing an image needs a file
  /// picker package that has not been approved — see the build log. The control
  /// stays in place (layout is locked) and says so plainly rather than failing
  /// silently.
  void _pickFromGallery() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pilih dari galeri belum tersedia.'),
        backgroundColor: Brand.ink,
      ),
    );
  }
}

/// Corner brackets with the red guide line across the middle.
class _ScanWindow extends StatelessWidget {
  const _ScanWindow();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 330,
        child: Stack(
          children: [
            const Positioned(top: 0, left: 0, child: _Corner(top: true, left: true)),
            const Positioned(top: 0, right: 0, child: _Corner(top: true, left: false)),
            const Positioned(bottom: 0, left: 0, child: _Corner(top: false, left: true)),
            const Positioned(bottom: 0, right: 0, child: _Corner(top: false, left: false)),
            Center(
              child: Container(height: 2.5, color: const Color(0xFFFF1A1A)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: Colors.white, width: 3);
    return SizedBox(
      width: 34,
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: top ? side : BorderSide.none,
            bottom: top ? BorderSide.none : side,
            left: left ? side : BorderSide.none,
            right: left ? BorderSide.none : side,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.background});

  final String text;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: size,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 40,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
