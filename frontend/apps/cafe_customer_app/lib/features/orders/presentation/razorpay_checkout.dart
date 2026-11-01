/// What the customer did in the gateway's checkout. A success here is only a claim until the server has checked it.
sealed class CheckoutOutcome {
  const CheckoutOutcome();
}

class CheckoutPaid extends CheckoutOutcome {
  const CheckoutPaid({required this.paymentRef, required this.signature});
  final String paymentRef;
  final String signature;
}

class CheckoutDismissed extends CheckoutOutcome {
  const CheckoutDismissed();
}

class CheckoutUnavailable extends CheckoutOutcome {
  const CheckoutUnavailable();
}

const razorpayCheckoutUrl = String.fromEnvironment('RAZORPAY_CHECKOUT_URL', defaultValue: 'https://checkout.razorpay.com/v1/checkout.js');
