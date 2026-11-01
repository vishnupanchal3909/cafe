// Run when real TEST-mode keys arrive: RAZORPAY_KEY_ID=rzp_test_... RAZORPAY_KEY_SECRET=... npm run razorpay:check
// It talks to the real Razorpay API. It creates one unpaid test order and nothing else.
import { razorpay } from '../src/modules/payments/providers/razorpay';

async function main() {
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;
  if (!keyId || !keySecret) throw new Error('Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.');
  if (!keyId.startsWith('rzp_test_')) throw new Error('Refusing to run: this check is for test-mode keys (rzp_test_...).');
  const creds = { keyId, keySecret };
  await razorpay.verifyCredentials!(creds);
  console.log('PASS  the keys are accepted');
  const reference = `check-${Date.now()}`;
  const session = await razorpay.createCheckout({ amount: '1.00', currency: 'INR', minorUnit: 2, reference, description: 'Connectivity check', returnUrl: 'https://example.com', methodCode: 'upi' }, creds);
  console.log(`PASS  order created: ${session.providerOrderRef}`);
  const fetched = await razorpay.fetchPayment(session.providerOrderRef, 2, creds);
  if (fetched.status !== 'pending') throw new Error(`Expected pending, got ${fetched.status}`);
  console.log('PASS  order payments read back as pending');
  const link = await razorpay.createPaymentLink!({ amount: '1.00', currency: 'INR', minorUnit: 2, reference: `${reference}-l`, description: 'Connectivity check', returnUrl: 'https://example.com', methodCode: 'payment_link' }, creds);
  console.log(`PASS  payment link created: ${link.shortUrl}`);
  const from = new Date(Date.now() - 7 * 86400_000);
  console.log(`PASS  settlements readable: ${(await razorpay.fetchSettlements(from, new Date(), creds, () => 2)).length} in 7 days`);
  console.log('\nNow do the manual run in docs/PAYMENT_INTEGRATION.md: real test payment, webhook, refund.');
}
main().catch((e) => { console.error(`FAIL  ${e.message}`); process.exit(1); });
