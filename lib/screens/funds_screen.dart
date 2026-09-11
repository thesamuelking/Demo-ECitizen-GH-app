import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ghanaserve/theme/app_theme.dart';
import 'package:ghanaserve/widgets/app_back_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghanaserve/providers/funds_provider.dart';

class FundsScreen extends ConsumerStatefulWidget { const FundsScreen({super.key}); @override ConsumerState<FundsScreen> createState() => _FundsScreenState(); }
class _FundsScreenState extends ConsumerState<FundsScreen> {
  double balance = 0;
  final amountController = TextEditingController();
  @override void dispose() { amountController.dispose(); super.dispose(); }
  void updateBalance(bool adding) {
    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) return;
    setState(() { balance += adding ? amount : -amount; if (balance < 0) balance += adding ? 0 : amount; amountController.clear(); });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(adding ? 'Funds added successfully.' : 'Withdrawal request submitted.')));
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const AppBackButton(), title: const Text('Funds')),
    body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: AppColors.ghGreen, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Available balance', style: GoogleFonts.inter(color: Colors.white70)), const SizedBox(height: 8), Text('GH₵ ${balance.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)), const SizedBox(height: 16), const Text('Ready to use for your next service payment', style: TextStyle(color: Colors.white70))])),
      const SizedBox(height: 22), Text('Manage funds', style: Theme.of(context).textTheme.displaySmall), const SizedBox(height: 10),
      Row(children: [Expanded(child: ElevatedButton.icon(onPressed: () => context.push('/funds/add'), icon: const Icon(Icons.add, size: 18), label: const Text('Add funds'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: () => context.push('/funds/withdraw'), icon: const Icon(Icons.arrow_upward, size: 18), label: const Text('Withdraw'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12))))]),
      const SizedBox(height: 24), Text('My cards', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), ..._cards(context),
      const SizedBox(height: 20), Text('Payment activity', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), Card(child: ListTile(leading: const Icon(Icons.receipt_long_outlined), title: const Text('No payment activity yet'), subtitle: Text('Your payment history will appear here.', style: Theme.of(context).textTheme.bodyMedium)))
    ]));

  List<Widget> _cards(BuildContext context) {
    final cards = ref.watch(paymentCardsProvider);
    return [
      ...cards.map((card) => Card(child: ListTile(leading: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary), title: Text('${card.brand} ending ${card.lastFour}'), subtitle: Text('${card.holder} · Expires ${card.expiry}')))),
      Card(child: ListTile(leading: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary), title: Text(cards.isEmpty ? 'No cards added yet' : 'Add another payment method'), subtitle: const Text('Debit, credit or Visa card'), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/funds/add-method'))),
    ];
  }
}
