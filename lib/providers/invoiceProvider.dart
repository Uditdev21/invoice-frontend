import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:invoice/providers/authProvider.dart';

enum InvoiceStatus { idle, loading, success, error }

class InvoiceNotifier extends StateNotifier<InvoiceStatus> {
  final Ref ref;
  List<dynamic>? _data = [];

  InvoiceNotifier(this.ref) : super(InvoiceStatus.idle);

  List<dynamic> get data => _data ?? []; // ✅ Corrected Getter

  Future<void> fetchInvoices() async {
    final token = ref.read(authProvider.notifier).token;
    if (token == null || token.isEmpty) {
      state = InvoiceStatus.error;
      return; // ✅ Prevent execution if token is null
    }

    state = InvoiceStatus.loading;
    final uri = Uri.parse(
        "https://cloud-invoice-backend.onrender.com/client/getinvoices");

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      });

      if (response.statusCode == 200) {
        _data = jsonDecode(response.body);
        print("Invoices: $_data");
        // ✅ Store invoices properly
        state = InvoiceStatus.success;
      } else {
        state = InvoiceStatus.error;
        print("Error: ${response.body}");
      }
    } catch (e) {
      state = InvoiceStatus.error;
    }
  }
}

final invoiceProvider = StateNotifierProvider<InvoiceNotifier, InvoiceStatus>(
  (ref) => InvoiceNotifier(ref),
);
