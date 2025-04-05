import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:url_launcher/url_launcher.dart';
import 'scanner_pag.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner Notas de Devolução',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(cameras: cameras),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomeScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _controller = TextEditingController();
  List<String> _lastSentItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/intercargo-transportes.png', width: 50),
            SizedBox(width: 10),
            Text('Scanner Notas de Devolução'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Digite os 44 caracteres:'),
                TextField(
                  controller: _controller,
                  maxLength: 44,
                  decoration: InputDecoration(hintText: 'Digite aqui'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    String textToSend = _controller.text;
                    _sendEmail(textToSend);
                  },
                  child: Text('Enviar'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _scanBarcode,
                  child: Text('Escanear Código de Barras'),
                ),
                SizedBox(height: 20),
                Text('Últimos Envios:'),
                _lastSentItems.isEmpty
                    ? Text('Nenhum envio realizado ainda.')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _lastSentItems.length,
                        itemBuilder: (context, index) {
                          return ListTile(title: Text(_lastSentItems[index]));
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          HomeScreen(cameras: widget.cameras)),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    String? barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BarcodePage()),
    );

    if (barcode != null) {
      setState(() {
        _controller.text = barcode;
      });
    }
  }

  Future<void> _sendEmail(String scannedText) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'nfedevolucao@teste.com.br',
      query:
          'subject=Nota Fiscal de Devolução&body=${Uri.encodeComponent(scannedText)}',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
      setState(() {
        _lastSentItems.add(scannedText);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o aplicativo de email')),
      );
    }
  }
}

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({required this.camera});

  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Capturar Nota Fiscal')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            print('Imagem capturada: ${image.path}');

            String? barcode = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BarcodePage()),
            );

            if (barcode != null) {
              print("Código escaneado: $barcode");
              Navigator.pop(context, barcode);
            }
          } catch (e) {
            print("Erro ao capturar imagem ou escanear código: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro: $e')),
            );
          }
        },
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}
