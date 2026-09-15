import 'package:lancebox/features/invoices/invoice.dart';

// Build repeatable example data; changing the title retains the same invoice ID.
Invoice sampleInvoice({String title = 'Design'}) => Invoice(
  id: '1',
  number: '0001',
  client: 'Client',
  sender: 'Sender',
  title: title,
  currency: 'NGN',
  date: DateTime(2026, 9, 11),
  items: const [
    InvoiceItem(description: 'Design', quantity: 2, unitPrice: 300000),
    InvoiceItem(description: 'Support', quantity: 1.5, unitPrice: 10001),
  ],
  vat: 7.5,
  shipping: 50000,
  bankNumber: '0123456789',
  bankName: 'Lance Bank',
  accountName: 'Sender',
  terms: 'Due on receipt',
);
