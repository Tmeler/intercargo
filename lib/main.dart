import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'scanner_pag.dart';
import 'minhas_notas.dart';
import 'package:intercargo/invoice_note.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

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
  bool _isDownloading = false;
  bool _isSendingEmail = false;
  bool _isSelectingFile = false;

  Future<void> _copyPdfFromAssets(String invoiceNumber) async {
    setState(() => _isDownloading = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/nota_$invoiceNumber.pdf';

      final byteData =
          await rootBundle.load('assets/nota-fiscal-notebook-dell.pdf');
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await OpenFile.open(filePath);

      final now = DateTime.now();
      final formattedDate =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      setState(() {
        _lastNotes.insert(
          0,
          InvoiceNote(
            produto: invoiceNumber,
            dataEmissao: formattedDate,
            filePath: filePath,
          ),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Nota fiscal $invoiceNumber carregada com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar nota: ${e.toString()}')),
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _selectPdfFile() async {
    setState(() => _isSelectingFile = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        final file = File(filePath);

        final invoiceNumber = fileName.replaceAll(RegExp(r'[^0-9]'), '');

        final now = DateTime.now();
        final formattedDate =
            '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

        setState(() {
          _lastNotes.insert(
            0,
            InvoiceNote(
              produto: invoiceNumber.isNotEmpty ? invoiceNumber : 'Sem número',
              dataEmissao: formattedDate,
              filePath: filePath,
            ),
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF $fileName carregado com sucesso!')),
        );
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar arquivo: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSelectingFile = false);
    }
  }

  Future<void> _sendEmail(BuildContext context, InvoiceNote note) async {
    if (_isSendingEmail) return;

    setState(() => _isSendingEmail = true);

    try {
      final file = File(note.filePath!);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo da nota não encontrado')),
        );
        return;
      }

      final subject = 'Nota Fiscal de Devolução - ${note.produto}';
      final body = 'Prezado(a),\n\n'
          'Segue em anexo a nota fiscal de devolução:\n\n'
          'Número: ${note.produto}\n'
          'Data: ${note.dataEmissao}\n\n'
          'Atenciosamente,\n'
          'Intercargo Transportes';

      // Priorizar flutter_email_sender que mantém melhor formatação
      try {
        final Email email = Email(
          body: body,
          subject: subject,
          recipients: [],
          attachmentPaths: [note.filePath!],
          isHTML: false,
        );

        await FlutterEmailSender.send(email);
        return;
      } catch (e) {
        debugPrint('Erro com flutter_email_sender: $e');
      }

      // Fallback para mailto com codificação correta
      final mailtoUri = Uri(
        scheme: 'mailto',
        queryParameters: {
          'subject': subject,
          'body': body.replaceAll('\n', '%0D%0A'), // Codificação para mailto
        },
      );

      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
        return;
      }

      // Fallback para Gmail Web
      try {
        final gmailUri = Uri(
          scheme: 'https',
          host: 'mail.google.com',
          path: '/mail/u/0/',
          queryParameters: {
            'view': 'cm',
            'fs': '1',
            'tf': '1',
            'su': subject,
            'body': body.replaceAll('\n', '%0A'), // Codificação para Gmail
            'attach': note.filePath!,
          },
        );

        if (await canLaunchUrl(gmailUri)) {
          await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        debugPrint('Erro ao abrir Gmail: $e');
      }

      await _showEmailClientErrorDialog(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar email: ${error.toString()}')),
      );
    } finally {
      setState(() => _isSendingEmail = false);
    }
  }

  Future<void> _showEmailClientErrorDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nenhum cliente de email configurado'),
        content: const Text(
          'Para enviar emails, você precisa configurar um cliente de email no seu dispositivo. '
          'Deseja configurar agora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri(scheme: 'mailto');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                final settingsUri =
                    Uri(scheme: 'package', path: 'com.android.settings');
                if (await canLaunchUrl(settingsUri)) {
                  await launchUrl(settingsUri);
                }
              }
            },
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }

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
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isSelectingFile ? null : _selectPdfFile,
                icon: Icon(Icons.attach_file, color: Colors.white),
                label: _isSelectingFile
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Selecionar PDF',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              SizedBox(height: 16),
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
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isDownloading
                    ? null
                    : () {
                        if (_controller.text.isNotEmpty) {
                          _copyPdfFromAssets(_controller.text);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Digite um número da nota fiscal')),
                          );
                        }
                      },
                child: _isDownloading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Buscar por Número',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isDownloading ? null : _scanBarcode,
                icon: Icon(Icons.camera_alt, color: Colors.white),
                label: Text('Escanear Código',
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
                            produto: note.produto,
                            data: note.dataEmissao,
                            onTap: () {
                              if (note.filePath != null) {
                                OpenFile.open(note.filePath);
                              }
                            },
                            onShare: _isSendingEmail
                                ? null
                                : () => _sendEmail(context, note),
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
      _copyPdfFromAssets(barcode);
    }
  }
}

class _InvoiceCard extends StatelessWidget {
  final String produto;
  final String data;
  final VoidCallback? onTap;
  final VoidCallback? onShare;

  const _InvoiceCard({
    required this.produto,
    required this.data,
    this.onTap,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Container(
          width: 160,
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Expanded(
                child: Center(
                  child:
                      Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),
                ),
              ),
              SizedBox(height: 8),
              Text(produto,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text(data,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (onShare != null)
                IconButton(
                  icon: Icon(Icons.email, color: Colors.blue),
                  onPressed: onShare,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
