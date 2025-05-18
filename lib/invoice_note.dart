class InvoiceNote {
  final String produto;
  final String dataEmissao;
  final String? filePath;

  InvoiceNote({
    required this.produto,
    required this.dataEmissao,
    this.filePath,
  });
}
