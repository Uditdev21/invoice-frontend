import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice/providers/authProvider.dart';
import 'package:invoice/providers/invoiceProvider.dart';
import 'package:share_plus/share_plus.dart';

class Homepage extends ConsumerStatefulWidget {
  const Homepage({super.key});

  @override
  ConsumerState<Homepage> createState() => _HomepageState();
}

class _HomepageState extends ConsumerState<Homepage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authProvider.notifier).token;
      if (token != null && token.isNotEmpty) {
        ref.read(invoiceProvider.notifier).fetchInvoices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceProvider);
    final invoiceNotifier = ref.watch(invoiceProvider.notifier);
    final invoices = invoiceNotifier.data; // ✅ Get data safely

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(invoiceProvider.notifier).fetchInvoices(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Invoice App'),
            ),
            ListTile(
              title: const Text('Create Invoice'),
              onTap: () {
                GoRouter.of(context).push('/createInvoice');
              },
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () {
                ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: invoiceState == InvoiceStatus.loading
              ? const CircularProgressIndicator()
              : invoiceState == InvoiceStatus.error
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Error fetching invoices",
                            style: TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(invoiceProvider.notifier)
                              .fetchInvoices(),
                          child: const Text("Retry"),
                        ),
                      ],
                    )
                  : invoices.isEmpty
                      ? const Text("No invoices available")
                      : ListView.builder(
                          itemCount: invoices.length,
                          itemBuilder: (context, index) {
                            final invoice = invoices[index];
                            // print(invoice); // ✅ Print invoice data
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text("Invoice ID: ${invoice['_id']}"),
                                subtitle: Text("Amount: \$${invoice['Cost']}"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Status: ${invoice['status']}"),
                                    IconButton(
                                      icon: const Icon(Icons.share),
                                      onPressed: () {
                                        String invoiceDetails =
                                            "Click the link to check INVOICE: \n\n"
                                            "🔗 https://invoice-frontend-fawn.vercel.app/#/invoice/${invoice['_id']}\n\n"
                                            "**Invoice Details:**\n"
                                            "🆔 Invoice ID: ${invoice['_id']}\n"
                                            "💰 Amount: \$${invoice['Cost']}\n";
                                        // "📌 Status: ${invoice['status']}";
                                        Share.share(invoiceDetails);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
