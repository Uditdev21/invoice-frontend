import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

final invoiceFutureProvider =
    FutureProvider.autoDispose.family<Uint8List, String>((ref, id) async {
  final response = await http.get(Uri.parse(
      'https://cloud-invoice-backend.onrender.com/client/getinvoice/$id'));

  if (response.statusCode == 200) {
    final invoiceUrl = jsonDecode(response.body)['InvoiceURL'];

    // Download the PDF
    final pdfResponse = await http.get(Uri.parse(invoiceUrl));
    if (pdfResponse.statusCode == 200) {
      return pdfResponse.bodyBytes;
    } else {
      throw Exception('Failed to download PDF');
    }
  } else {
    throw Exception('Failed to load invoice data');
  }
});

class InvoicePage extends ConsumerStatefulWidget {
  final String id;
  const InvoicePage({Key? key, required this.id}) : super(key: key);

  @override
  ConsumerState<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends ConsumerState<InvoicePage> {
  PdfControllerPinch? pdfController;
  Uint8List? pdfData;

  void _downloadPDF() async {
    final invoiceAsyncValue = ref.watch(invoiceFutureProvider(widget.id));

    invoiceAsyncValue.when(
      data: (pdfBytes) async {
        final response = await http.get(Uri.parse(
            'https://cloud-invoice-backend.onrender.com/client/getinvoice/${widget.id}'));

        if (response.statusCode == 200) {
          final invoiceUrl = jsonDecode(response.body)['InvoiceURL'];
          print("Downloading from URL: $invoiceUrl");

          final anchor = html.AnchorElement(href: invoiceUrl)
            ..setAttribute('download', 'invoice_${widget.id}.pdf')
            ..style.display = 'none';

          html.document.body?.append(anchor);
          anchor.click();
          anchor.remove();

          print("Download triggered successfully");
        } else {
          print("Failed to fetch invoice URL.");
        }
      },
      loading: () => print("Loading invoice..."),
      error: (error, stack) => print("Error fetching invoice: $error"),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoiceAsyncValue = ref.watch(invoiceFutureProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: Text('Invoice Details')),
      body: invoiceAsyncValue.when(
        data: (pdfBytes) {
          pdfData = pdfBytes;
          pdfController = PdfControllerPinch(
            document: PdfDocument.openData(pdfBytes),
          );

          return PdfViewPinch(controller: pdfController!);
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error: ${error.toString()}')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _downloadPDF,
        child: Icon(Icons.download),
      ),
    );
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }
}
