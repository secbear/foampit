import type { ContractModel } from "./model.js";

const canonicalDecimal = /^[1-9][0-9]*$/;
const maximumPortableTag = 536_870_911;
const firstReservedTag = 19_000;
const lastReservedTag = 19_999;

export function isPortableWireTag(value: string): boolean {
  if (!canonicalDecimal.test(value)) return false;
  const tag = Number(value);
  return tag <= maximumPortableTag && (tag < firstReservedTag || tag > lastReservedTag);
}

export function assertPortableWireTags(model: Readonly<ContractModel>): void {
  for (const sum of model.closedSums) {
    for (const variant of sum.variants) {
      if (variant.wireTag === undefined) {
        throw new Error("contract/missing-wire-tag");
      }
      if (!isPortableWireTag(variant.wireTag)) {
        throw new Error("contract/invalid-wire-tag");
      }
    }
  }
}
