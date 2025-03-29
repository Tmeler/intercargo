import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:email_launcher/email_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scanner Notas de Devolução',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _controller = TextEditingController();
  List<String> _lastSentItems = [];
  String scannedData = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/intercargo-transportes.png', width: 50), // Caminho correto da logo
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
                  decoration: InputDecoration(
                    hintText: 'Digite aqui',
                  ),
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
                  onPressed: _scanNFE,
                  child: Text('Escanear Nota Fiscal'),
                ),
                SizedBox(height: 20),
                Text('Últimos Envios:'),
                _lastSentItems.isEmpty
                    ? Text('Nenhum envio realizado ainda.')
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _lastSentItems.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_lastSentItems[index]),
                    );
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
                  MaterialPageRoute(builder: (context) => HomeScreen()),
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

  Future<void> _scanNFE() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakePictureScreen(camera: firstCamera),
      ),
    );
  }

  Future<void> _sendEmail(String scannedText) async {
    final email = Email(
      body: scannedText,
      subject: 'Nota Fiscal de Devolução',
      to: ['nfedevolucao@teste.com.br'], // Corrigido o nome do parâmetro
    );

    await EmailLauncher.launch(email);
    setState(() {
      _lastSentItems.add(scannedText);
    });
  }
}

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  TakePictureScreen({required this.camera});

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
            // Implemente a leitura da NFE aqui
          } catch (e) {
            print(e);
          }
        },
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}
