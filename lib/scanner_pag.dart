import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodePage extends StatefulWidget {
  const BarcodePage({Key? key}) : super(key: key);

  @override
  _BarcodePageState createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  String barcode = '';
  bool isLoading = true;
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 1000,
    formats: [BarcodeFormat.all], // Foco em códigos de barras
  );

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    controller.start();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Escanear Código de Barras")),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            fit: BoxFit.contain,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final Barcode firstBarcode = barcodes.first;

                // Filtra apenas códigos de barras (não QR codes)
                if (firstBarcode.format != BarcodeFormat.qrCode) {
                  final String result = firstBarcode.rawValue ?? '';
                  if (result.isNotEmpty) {
                    controller.stop();
                    setState(() {
                      barcode = result;
                      isLoading = false;
                    });
                    Navigator.pop(context, result);
                  }
                }
              }
            },
          ),
          if (isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Escaneando código de barras..."),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancelar"),
                  ),
                ],
              ),
            ),
          // Overlay com guia para código de barras
          Align(
            alignment: Alignment.center,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 2,
              color: Colors.red.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
