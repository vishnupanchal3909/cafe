import { createHmac, randomInt, timingSafeEqual } from 'node:crypto';
import { config } from '../../common/config';

/** A four-digit PIN for a table session, read out by staff to the guests sitting there. */
export const newTablePin = () => String(randomInt(0, 10_000)).padStart(4, '0');

/** Proof that this device entered the session's PIN. Derived, so nothing is stored and it cannot be guessed. */
export const tablePinProof = (sessionPublicId: string) => createHmac('sha256', config.encryptionKey).update(`table-pin:${sessionPublicId}`).digest('base64url');

export function validPinProof(sessionPublicId: string, proof: string | undefined) {
  if (!proof) return false;
  const want = Buffer.from(tablePinProof(sessionPublicId));
  const got = Buffer.from(proof);
  return want.length === got.length && timingSafeEqual(want, got);
}
