# Payment Integration

**Razorpay is the chosen gateway. Each cafe receives its money directly, in its own Razorpay account.**

Status: **built and tested against a local simulator shaped after Razorpay's public docs. It has never talked to the real Razorpay with a real key.** The simulator proves our side of the contract, not Razorpay's behaviour. The first real test-mode run below is still required before taking money.

## What exists

| Capability | How it works |
|---|---|
| Key setup | Owner saves keys in Settings, then taps Test connection. Keys take no money until the gateway has accepted them. Secrets are encrypted and never returned |
| Online checkout | Server creates a Razorpay order for what is still owed, and Razorpay's own `checkout.js` opens on the customer's page. UPI, cards and the rest are offered by Razorpay. Card data never touches our servers |
| Confirmation | Three independent routes: signed webhook, the browser callback (signature, then server-to-server check), and a background sweep every minute |
| Capture | Authorized payments are captured automatically, since Razorpay auto-refunds uncaptured ones |
| Part payment | A guest can pay part of the bill. Online and cash can be mixed. One invoice is issued when the balance reaches zero |
| Bill split | Staff split a balance into equal or custom parts |
| Payment links | Staff create a link for an order. The native customer app also uses these, as it has no `checkout.js` |
| Cash | Confirmed by an authorized staff member only, optionally against an open cash register |
| Refunds | Requested, then approved by someone with that permission. Partial or full. A credit note and reversing ledger entries follow. A failed refund releases its amount |
| Settlements | Fetched every 6 hours or on demand, matched to our payments line by line. Anything we cannot match is marked Needs review |
| Accounting | Payment: Dr gateway clearing, Cr receivable. Settlement: Dr bank and gateway fees, Cr clearing. Fees are settled sales minus what reached the bank, so the books always match the bank |
| Reports | Payment list with fees, refunds, settlements, and a summary by method |

## Guarantees

- **A browser can never mark a payment paid.** A valid signature only triggers a server-to-server check with Razorpay.
- **The server sets the amount.** It is bounded by what is owed, and a signed event for a different sum is recorded and not credited.
- **Duplicate events are safe:** unique event ids, plus idempotent capture and posting. Events may arrive in any order.
- **Temporary faults answer 503,** so Razorpay resends. A redelivery of a failed event is processed, not dropped.
- **An abandoned checkout expires after 30 minutes** (or when the guest closes it), which frees the balance. A capture arriving later still counts, because the money is real. If that overpays an order it is recorded, audited and raised to staff for a refund.
- **Never stored:** card numbers, CVV, UPI PINs, or the customer's contact details from webhook payloads.
- Database checks and triggers enforce most of this again underneath the application (`0007`, `0012`).

## When your keys arrive

Use **test-mode** keys first (`rzp_test_...`), from Razorpay Dashboard > Account & Settings > API Keys.

1. **Check the keys against the real API.** This creates one unpaid test order and one test link, and refuses live keys:
   ```bash
   cd backend
   RAZORPAY_KEY_ID=rzp_test_xxx RAZORPAY_KEY_SECRET=xxx npm run razorpay:check
   ```
2. **Expose the API over HTTPS** so Razorpay can reach it (a staging server, or a tunnel for a test), and set `PUBLIC_API_URL` to it.
3. **Save the keys:** Owner app > Settings > Payment gateway > Add. Choose sandbox. Leave the webhook secret for step 5 if you have not chosen one, then save again with it. Copy the webhook URL it shows.
4. **Add the webhook:** Dashboard > Account & Settings > Webhooks > Add. Paste the URL. Choose a secret. Tick: `payment.authorized`, `payment.captured`, `payment.failed`, `order.paid`, `refund.processed`, `refund.failed`, `payment_link.paid`.
5. **Save the same secret in the Owner app, then tap Test connection.** Online payments switch on.
6. **Do the manual run** with Razorpay's test cards and test UPI, and tick each one:
   - [ ] Pay a whole bill. It shows Paid, an invoice appears, and the webhook row is `processed`
   - [ ] Close the checkout without paying. The bill can be paid again
   - [ ] Fail a payment, then retry inside the checkout
   - [ ] Pay part online, the rest in cash
   - [ ] Create a payment link and pay it
   - [ ] Partial refund and full refund. Refund reaches `succeeded` after `refund.processed`
   - [ ] Fetch settlements once one exists, and check it says Reconciled with the right fee. **Razorpay's docs do not say plainly whether `fee` includes `tax`, so check this one against your dashboard**
7. **Going live:** complete Razorpay's KYC, repeat steps 3 to 5 with `rzp_live_` keys and environment `live`. A live key always wins over a sandbox one. Do one small real payment and refund it.

## Who holds the keys

Each cafe needs its own Razorpay account, keys and webhook, since each cafe receives its own money. Every cafe owner will do steps 3 to 5 once. Any keys you share first can only test the system with your own account.

## Provider port

`backend/src/modules/payments/providers/provider.ts`. Razorpay is complete. Stripe and Cashfree adapters from early work remain in the code, are hidden from the UI, and lack payment links, signature callback and settlement matching. Adding a gateway means implementing this interface.

## Not built

| Item | Note |
|---|---|
| Disputes and chargebacks | `payment.dispute.*` events are ignored. Handle them in the Razorpay dashboard for now |
| Overpayment refund | Flagged and refundable, but the credit note treats it like a sale refund, so its tax split would be wrong. Needs an accountant's view |
| Razorpay native SDK | The mobile customer app uses payment links rather than the in-app SDK |
| Subscription billing through Razorpay | Platform charges are undecided |
