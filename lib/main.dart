import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:url_launcher/url_launcher.dart';
import 'scanner_pag.dart';
import 'minhas_notas.dart';
import 'package:intercargo/invoice_note.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
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
  List<InvoiceNote> _lastNotes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[200],
              radius: 20,
              child: Icon(Icons.local_shipping, color: Colors.black54),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Intercargo Transportes',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('NF Intercargo',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Digite o número da nota fiscal',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLength: 44,
                decoration: InputDecoration(
                  hintText: 'Insira o número aqui',
                  counterText: '',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 4),
              Text('Exemplo: 123456789',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _scanBarcode,
                child: Text('Escanear Nota',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              SizedBox(height: 24),
              Text('Últimas Notas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Container(
                height: 220,
                child: _lastNotes.isEmpty
                    ? Center(child: Text('Nenhuma nota ainda.'))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _lastNotes.length,
                        separatorBuilder: (_, __) => SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final note = _lastNotes[i];
                          return _InvoiceCard(
                            valor: note.valor,
                            produto: note.produto,
                            data: note.dataEmissao,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (idx) {
          if (idx == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MinhasNotasPage(notinhas: _lastNotes),
              ),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Início'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Minhas Notas'),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    String? barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BarcodePage()),
    );
    if (barcode != null && barcode.isNotEmpty) {
      _controller.text = barcode;
      final now = DateTime.now();
      final formatted = '${now.day.toString().padLeft(2, '0')}/'
          '${now.month.toString().padLeft(2, '0')}/'
          '${now.year}';
      setState(() {
        _lastNotes.insert(
          0,
          InvoiceNote(
            valor: 'R\$ 0.00',
            produto: barcode,
            dataEmissao: formatted,
          ),
        );
      });
    }
  }
}

class _InvoiceCard extends StatelessWidget {
  final String valor;
  final String produto;
  final String data;
  const _InvoiceCard({
    required this.valor,
    required this.produto,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        width: 160,
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Valor: $valor',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text('Imagem do Produto\nou referência',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600])),
              ),
            ),
            SizedBox(height: 8),
            Text(produto,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text(data,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
