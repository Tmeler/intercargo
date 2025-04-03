import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class QRCodePage extends StatefulWidget {
  const QRCodePage({Key? key}) : super(key: key);

  @override
  _QRCodePageState createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  String ticket = '';
  bool isLoading = true; // Estado de carregamento

  Future<void> scanQRCode() async {
    try {
      String result = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666",
        "Cancelar",
        true,
        ScanMode.BARCODE,
      );

      print("Resultado do scanner: $result");

      if (result != '-1') {
        setState(() {
          ticket = result;
          isLoading = false;
        });

        await Future.delayed(
          Duration(seconds: 2),
        ); // Pequena pausa antes de fechar
        Navigator.pop(context, result);
      } else {
        print("Escaneamento cancelado.");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao escanear: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    scanQRCode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Escanear Nota Fiscal")),
      body: Center(
        child:
            isLoading
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text("Escaneando, aguarde..."),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Botão de cancelamento
                      },
                      child: Text("Cancelar"),
                    ),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Código Escaneado:", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Text(
                      ticket,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, ticket),
                      child: Text("Confirmar"),
                    ),
                  ],
                ),
      ),
    );
  }
}
