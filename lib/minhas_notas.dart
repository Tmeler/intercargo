import 'package:flutter/material.dart';
import 'package:intercargo/invoice_note.dart';

class MinhasNotasPage extends StatefulWidget {
  final List<InvoiceNote> notinhas;

  const MinhasNotasPage({Key? key, required this.notinhas}) : super(key: key);

  @override
  _MinhasNotasPageState createState() => _MinhasNotasPageState();
}

class _MinhasNotasPageState extends State<MinhasNotasPage> {
  final TextEditingController _controller = TextEditingController();
  String? _message;

  void _submit() {
    if (_controller.text.length != 44) {
      setState(() {
        _message = 'O número da nota deve conter 44 dígitos.';
      });
    } else {
      setState(() {
        _message = 'Nota enviada com sucesso!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Notas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Digite o número da nota fiscal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLength: 44,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ex: 12345678901234567890123456789012345678901234',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (_message != null) ...[
              SizedBox(height: 12),
              Text(
                _message!,
                style: TextStyle(
                  color: _message == 'Nota enviada com sucesso!'
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Enviar',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Últimas Notas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            widget.notinhas.isEmpty
                ? Center(child: Text('Nenhuma nota ainda.'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.notinhas.length,
                    itemBuilder: (context, index) {
                      final note = widget.notinhas[index];
                      return ListTile(
                        title: Text(note.produto),
                        subtitle: Text('Valor: ${note.valor}'),
                        trailing: Text(note.dataEmissao),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
