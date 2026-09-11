import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentCard {
  final String holder;
  final String lastFour;
  final String expiry;
  final String brand;

  const PaymentCard({required this.holder, required this.lastFour, required this.expiry, required this.brand});
}

final paymentCardsProvider = StateProvider<List<PaymentCard>>((ref) => const []);
