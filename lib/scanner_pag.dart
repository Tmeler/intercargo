import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class BarcodePage extends StatefulWidget {
  const BarcodePage({Key? key}) : super(key: key);

  @override
  _BarcodePageState createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _isLoading = true;
  bool _flashEnabled = false;
  CameraFacing _cameraFacing = CameraFacing.back;
  bool _hasError = false;
  bool _isScannerReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initScanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;

    if (state == AppLifecycleState.resumed) {
      _controller!.start();
    } else if (state == AppLifecycleState.paused) {
      _controller!.stop();
    }
  }

  Future<void> _initScanner() async {
    try {
      final status = await Permission.camera.request();
      if (!mounted) return;

      if (!status.isGranted) {
        _handleError('Permissão da câmera negada');
        return;
      }

      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        formats: [BarcodeFormat.all],
        facing: _cameraFacing,
      );

      setState(() => _isScannerReady = true);
      setState(() => _isLoading = false);
    } catch (e) {
      _handleError('Erro ao iniciar scanner: ${e.toString()}');
    }
  }

  void _handleError(String message) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _hasError = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context, '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escanear Código de Barras"),
        actions: [
          IconButton(
            icon: Icon(
              _flashEnabled ? Icons.flash_on : Icons.flash_off,
              color: _flashEnabled ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              if (_controller == null) return;
              setState(() => _flashEnabled = !_flashEnabled);
              _controller!.toggleTorch();
            },
          ),
          IconButton(
            icon: Icon(
              _cameraFacing == CameraFacing.back
                  ? Icons.camera_rear
                  : Icons.camera_front,
            ),
            onPressed: () async {
              if (_controller == null) return;

              setState(() {
                _cameraFacing = _cameraFacing == CameraFacing.back
                    ? CameraFacing.front
                    : CameraFacing.back;
                _isLoading = true;
              });

              await _controller!.stop();
              await _controller!.switchCamera();
              await _controller!.start();

              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
      body: _buildScannerContent(),
    );
  }

  Widget _buildScannerContent() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Erro ao iniciar scanner'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Voltar'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        if (_isScannerReady && _controller != null)
          MobileScanner(
            controller: _controller!,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first.rawValue;
                if (barcode != null && barcode.isNotEmpty) {
                  _controller?.stop();
                  Navigator.pop(context, barcode);
                }
              }
            },
          ),
        _buildScannerOverlay(),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.width * 0.7,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
