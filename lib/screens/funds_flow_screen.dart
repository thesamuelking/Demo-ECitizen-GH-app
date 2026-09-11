import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ghanaserve/widgets/app_back_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghanaserve/providers/funds_provider.dart';

class AddPaymentMethodScreen extends ConsumerStatefulWidget {
  const AddPaymentMethodScreen({super.key});
  @override ConsumerState<AddPaymentMethodScreen> createState() => _AddPaymentMethodState();
}
class _AddPaymentMethodState extends ConsumerState<AddPaymentMethodScreen> {
  final holder = TextEditingController();
  final number = TextEditingController();
  final expiry = TextEditingController();
  @override void dispose() { holder.dispose(); number.dispose(); expiry.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => _FundsFormScaffold(
        title: 'Add payment method',
        child: Column(children: [
          _Field(label: 'Cardholder name', controller: holder),
          _Field(label: 'Card number', controller: number, keyboardType: TextInputType.number),
          Row(children: [Expanded(child: _Field(label: 'Expiry date', hint: 'MM / YY', controller: expiry)), const SizedBox(width: 12), const Expanded(child: _Field(label: 'CVV', keyboardType: TextInputType.number, obscure: true))]),
          const SizedBox(height: 8),
          const Text('Debit, credit and Visa cards are securely tokenized for future payments.'),
          const SizedBox(height: 18),
          _SubmitButton(label: 'Save payment method', onPressed: () { final digits = number.text.replaceAll(' ', ''); if (holder.text.trim().isEmpty || digits.length < 4 || expiry.text.trim().isEmpty) return; ref.read(paymentCardsProvider.notifier).state = [...ref.read(paymentCardsProvider), PaymentCard(holder: holder.text.trim(), lastFour: digits.substring(digits.length - 4), expiry: expiry.text.trim(), brand: 'Card')]; _saved(context); }),
        ]),
      );
}

class AddFundsScreen extends ConsumerWidget {
  const AddFundsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _ChoiceScaffold(
        title: 'Add funds',
        subtitle: 'Choose how you want to fund your account.',
        choices: [
          _Choice(icon: Icons.phone_android_rounded, title: 'Mobile money', subtitle: 'Pay with your mobile wallet', onTap: () => _showForm(context, 'Mobile money number', 'Add funds via mobile money')),
          _Choice(icon: Icons.credit_card_rounded, title: 'My cards', subtitle: 'Use a saved debit or credit card', onTap: () { if (ref.read(paymentCardsProvider).isEmpty) { _showNoCard(context); } else { _showCardForm(context, ref.read(paymentCardsProvider)); } }),
        ],
      );

  static void _showForm(BuildContext context, String label, String title) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _FundsFormScaffold(title: title, child: Column(children: [_Field(label: label), _Field(label: 'Amount', prefix: 'GH₵ '), const SizedBox(height: 12), _SubmitButton(label: 'Continue securely', onPressed: () => _saved(context))]))));
  static void _showNoCard(BuildContext context) => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('No card added yet'),
          content: const Text('Add a payment method before choosing My cards.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () { Navigator.of(dialogContext).pop(); context.push('/funds/add-method'); }, child: const Text('Add payment method')),
          ],
        ),
      );
  static void _showCardForm(BuildContext context, List<PaymentCard> cards) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _SelectCardForm(cards: cards)));
}

class WithdrawFundsScreen extends ConsumerWidget {
  const WithdrawFundsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => _ChoiceScaffold(
        title: 'Withdraw funds',
        subtitle: 'Choose where you want your funds sent.',
        choices: [
          _Choice(icon: Icons.phone_android_rounded, title: 'Mobile money', subtitle: 'Withdraw to your mobile wallet', onTap: () => _showForm(context, 'Mobile money number')),
          _Choice(icon: Icons.credit_card_rounded, title: 'My cards', subtitle: 'Withdraw to a saved card', onTap: () { if (ref.read(paymentCardsProvider).isEmpty) { AddFundsScreen._showNoCard(context); } else { AddFundsScreen._showCardForm(context, ref.read(paymentCardsProvider)); } }),
        ],
      );

  static void _showForm(BuildContext context, String destination) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _FundsFormScaffold(title: 'Withdraw to $destination', child: Column(children: [_Field(label: destination), _Field(label: 'Amount', prefix: 'GH₵ '), const SizedBox(height: 12), _SubmitButton(label: 'Submit withdrawal', onPressed: () => _saved(context))]))));
}

class _SelectCardForm extends StatefulWidget {
  final List<PaymentCard> cards;
  const _SelectCardForm({required this.cards});
  @override State<_SelectCardForm> createState() => _SelectCardFormState();
}
class _SelectCardFormState extends State<_SelectCardForm> {
  int selected = 0;
  final amount = TextEditingController();
  @override void dispose() { amount.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => _FundsFormScaffold(title: 'Add funds with my card', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Select card', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), ...List.generate(widget.cards.length, (index) => RadioListTile<int>(value: index, groupValue: selected, onChanged: (value) => setState(() => selected = value!), title: Text('${widget.cards[index].brand} ending ${widget.cards[index].lastFour}'), subtitle: Text(widget.cards[index].holder), contentPadding: EdgeInsets.zero)), const SizedBox(height: 10), _Field(label: 'Amount', prefix: 'GH₵ ', controller: amount, keyboardType: TextInputType.number), _SubmitButton(label: 'Continue securely', onPressed: () { if (amount.text.trim().isNotEmpty) _saved(context); })]));
}

void _saved(BuildContext context) { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted securely.'))); }

class _FundsFormScaffold extends StatelessWidget {
  final String title; final Widget child;
  const _FundsFormScaffold({required this.title, required this.child});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(leading: const AppBackButton(), title: Text(title)), body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Card(child: Padding(padding: const EdgeInsets.all(18), child: child))));
}
class _ChoiceScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_Choice> choices;
  const _ChoiceScaffold({required this.title, required this.subtitle, required this.choices});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(leading: const AppBackButton(), title: Text(title)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            ...choices.map((choice) => Card(
                  child: ListTile(
                    leading: Icon(choice.icon, color: Theme.of(context).colorScheme.primary),
                    title: Text(choice.title),
                    subtitle: Text(choice.subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: choice.onTap,
                  ),
                )),
          ],
        ),
      );
}
class _Choice { final IconData icon; final String title; final String subtitle; final VoidCallback onTap; const _Choice({required this.icon, required this.title, required this.subtitle, required this.onTap}); }
class _Field extends StatelessWidget { final String label; final String? hint; final String? prefix; final TextInputType? keyboardType; final bool obscure; final TextEditingController? controller; const _Field({required this.label, this.hint, this.prefix, this.keyboardType, this.obscure = false, this.controller}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(controller: controller, obscureText: obscure, keyboardType: keyboardType, decoration: InputDecoration(labelText: label, hintText: hint, prefixText: prefix))); }
class _SubmitButton extends StatelessWidget { final String label; final VoidCallback onPressed; const _SubmitButton({required this.label, required this.onPressed}); @override Widget build(BuildContext context) => SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onPressed, child: Text(label))); }
