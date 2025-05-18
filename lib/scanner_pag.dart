import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// importe o permission_handler
import 'package:permission_handler/permission_handler.dart';

class BarcodePage extends StatefulWidget {
  const BarcodePage({Key? key}) : super(key: key);

  @override
  _BarcodePageState createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  late MobileScannerController controller;
  bool _isLoading = true;
  bool _flashEnabled = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      formats: [BarcodeFormat.all],
    );
    _startScanner();
  }

  Future<void> _startScanner() async {
    // 1) Solicita permissão de câmera
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      // Se o usuário negar, retorna sem código
      Navigator.pop(context, '');
      return;
    }

    // 2) Inicia o scanner
    try {
      await controller.start();
      setState(() => _isLoading = false);
    } catch (e) {
      // Se falhar por outro motivo, fecha também
      Navigator.pop(context, '');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Escanear Código de Barras"),
        actions: [
          IconButton(
            icon: Icon(
              _flashEnabled ? Icons.flash_on : Icons.flash_off,
              color: _flashEnabled ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              setState(() => _flashEnabled = !_flashEnabled);
              controller.toggleTorch();
            },
          ),
          IconButton(
            icon: Icon(
              _cameraFacing == CameraFacing.back
                  ? Icons.camera_rear
                  : Icons.camera_front,
            ),
            onPressed: () {
              setState(() {
                _cameraFacing = (_cameraFacing == CameraFacing.back)
                    ? CameraFacing.front
                    : CameraFacing.back;
              });
              controller.switchCamera();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final code = barcodes.first.rawValue;
                      if (code != null && code.isNotEmpty) {
                        controller.stop();
                        Navigator.pop(context, code);
                      }
                    }
                  },
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
