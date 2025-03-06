import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:invoice/providers/authProvider.dart';

final invoiceProvider =
    StateNotifierProvider<InvoiceNotifier, Map<String, dynamic>>(
  (ref) => InvoiceNotifier(),
);

class InvoiceNotifier extends StateNotifier<Map<String, dynamic>> {
  InvoiceNotifier()
      : super({
          "client_info": {
            "name": "",
            "address": "",
            "city_state_zip": "",
          },
          "invoice_info": {
            "invoice_number": "",
            "date": "",
            "due_date": "",
          },
          "items": [], // 2D List: [[name, quantity, price]]
        });

  void updateClientInfo(String key, String value) {
    state = {
      ...state,
      "client_info": {
        ...state["client_info"],
        key: value,
      }
    };
  }

  void updateInvoiceInfo(String key, String value) {
    state = {
      ...state,
      "invoice_info": {
        ...state["invoice_info"],
        key: value,
      }
    };
  }

  void addItem() {
    state = {
      ...state,
      "items": [
        ...state["items"],
        ["", 1, 0.0],
      ]
    };
  }

  void updateItem(int index, int fieldIndex, dynamic value) {
    List<List<dynamic>> items = List.from(state["items"]);
    items[index][fieldIndex] = value;
    state = {
      ...state,
      "items": items,
    };
  }

  void removeItem(int index) {
    List<List<dynamic>> items = List.from(state["items"]);
    items.removeAt(index);
    state = {
      ...state,
      "items": items,
    };
  }

  void submitInvoice(WidgetRef ref, BuildContext context) async {
    try {
      final token = ref.read(authProvider.notifier).token;
      final uri = Uri.parse(
          'https://cloud-invoice-backend.onrender.com/client/createinvoice');
      final response = await http.post(uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode(state));
      print(response.body);
      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Success"),
            content: const Text("Invoice uploaded successfully"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  resetForm();
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void resetForm() {
    state = {
      "client_info": {
        "name": "",
        "address": "",
        "city_state_zip": "",
      },
      "invoice_info": {
        "invoice_number": "",
        "date": "",
        "due_date": "",
      },
      "items": [],
    };
  }
}

class InvoiceCreatePage extends ConsumerWidget {
  const InvoiceCreatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = ref.watch(invoiceProvider);
    final invoiceNotifier = ref.read(invoiceProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("Create Invoice")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Client Info
            TextField(
              decoration: const InputDecoration(labelText: "Client Name"),
              onChanged: (value) =>
                  invoiceNotifier.updateClientInfo("name", value),
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Address"),
              onChanged: (value) =>
                  invoiceNotifier.updateClientInfo("address", value),
            ),
            TextField(
              decoration: const InputDecoration(labelText: "City, State, Zip"),
              onChanged: (value) =>
                  invoiceNotifier.updateClientInfo("city_state_zip", value),
            ),
            const Divider(),

            // Invoice Info
            TextField(
              decoration: const InputDecoration(labelText: "Invoice Number"),
              onChanged: (value) =>
                  invoiceNotifier.updateInvoiceInfo("invoice_number", value),
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Date (YYYY-MM-DD)"),
              onChanged: (value) =>
                  invoiceNotifier.updateInvoiceInfo("date", value),
            ),
            TextField(
              decoration:
                  const InputDecoration(labelText: "Due Date (YYYY-MM-DD)"),
              onChanged: (value) =>
                  invoiceNotifier.updateInvoiceInfo("due_date", value),
            ),
            const Divider(),

            // Item List
            Expanded(
              child: ListView.builder(
                itemCount: invoice["items"].length,
                itemBuilder: (context, index) {
                  return ItemInput(index: index);
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => invoiceNotifier.addItem(),
              child: const Text("Add Item"),
            ),

            // Submit Button
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("clicked");
                invoiceNotifier.submitInvoice(ref, context);
              },
              child: const Text("Submit Invoice"),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemInput extends ConsumerWidget {
  final int index;

  const ItemInput({super.key, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceNotifier = ref.read(invoiceProvider.notifier);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: "Product Name"),
              onChanged: (value) => invoiceNotifier.updateItem(index, 0, value),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: "Quantity"),
              keyboardType: TextInputType.number,
              onChanged: (value) => invoiceNotifier.updateItem(
                  index, 1, int.tryParse(value) ?? 1),
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
              onChanged: (value) => invoiceNotifier.updateItem(
                  index, 2, double.tryParse(value) ?? 0.0),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => invoiceNotifier.removeItem(index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
