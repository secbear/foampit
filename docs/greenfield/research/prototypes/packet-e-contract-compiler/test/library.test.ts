import { createTester } from "@typespec/compiler/testing";
import { expect, it } from "vitest";

const { diagnose } = createTester(new URL("../", import.meta.url).pathname, {
  libraries: ["contract"],
})
  .importLibraries()
  .using("PacketE.Contract");

function expectDiagnostic(
  diagnostics: Awaited<ReturnType<typeof diagnose>>,
  code: string,
): void {
  expect(diagnostics).toEqual(
    expect.arrayContaining([expect.objectContaining({ code })]),
  );
}

it("accepts a contract root namespace", async () => {
  expect(await diagnose(`@contractRoot namespace Slice;`)).toEqual([]);
});

it("rejects a program without a contract root", async () => {
  expectDiagnostic(
    await diagnose(`model Rootless {}`),
    "contract/missing-contract-root",
  );
});

it("rejects multiple contract roots", async () => {
  expectDiagnostic(
    await diagnose(
      `@contractRoot namespace First {} @contractRoot namespace Second {}`,
    ),
    "contract/multiple-contract-roots",
  );
});

it("rejects conflicting stable IDs on one target", async () => {
  expectDiagnostic(
    await diagnose(
      `@stableId("core.start") @stableId("core.other") op Start(): void;`,
    ),
    "contract/conflicting-stable-id",
  );
});

it("rejects repeated identical stable IDs on one target", async () => {
  expectDiagnostic(
    await diagnose(`@stableId("core.start") @stableId("core.start") op Start(): void;`),
    "contract/conflicting-stable-id",
  );
});

it("rejects a noncanonical stable ID", async () => {
  expectDiagnostic(
    await diagnose(`@stableId("Core.Start") op Start(): void;`),
    "contract/invalid-stable-id",
  );
});

it("rejects a duplicate stable ID in the graph", async () => {
  expectDiagnostic(
    await diagnose(
      `@stableId("core.start") op Start(): void; @stableId("core.start") op Other(): void;`,
    ),
    "contract/duplicate-stable-id",
  );
});

it("rejects duplicate union wire tags in the graph", async () => {
  expectDiagnostic(
    await diagnose(
      `@wireTag("1") union Outcome { @wireTag("1") ok: void, @wireTag("1") failed: void }`,
    ),
    "contract/duplicate-wire-tag",
  );
});

it("rejects repeated identical wire tags on one target", async () => {
  expectDiagnostic(
    await diagnose(
      `union Outcome { @wireTag("1") @wireTag("1") ok: void }`,
    ),
    "contract/conflicting-wire-tag",
  );
});

it.each(["19000", "19999", "536870912"])("rejects protobuf-invalid wire tag %s at the source", async (tag) => {
  expectDiagnostic(
    await diagnose(`@contractRoot namespace Slice {} union Outcome { @wireTag("${tag}") ok: void }`),
    "contract/invalid-wire-tag",
  );
});

it("accepts the maximum portable wire tag", async () => {
  expect(await diagnose(`@contractRoot namespace Slice {} union Outcome { @wireTag("536870911") ok: void }`)).toEqual([]);
});

it("rejects repeated operation-contract definitions on one operation", async () => {
  expectDiagnostic(
    await diagnose(
      `@operationContract(#{ operationId: "operation.start", callClass: "durableOperationMutation", resultBranches: #["accepted", "rejected", "recovery"], allowedRequestErrors: #[], allowedRecoveryErrors: #[], allowedKnownFailures: #[], allowedAmbiguities: #[], recoveryCoordinates: #[], matrixIds: #[], result: #{ carrierKind: "newDurableOperation", schemaStableId: "result.operation.start" } }) @operationContract(#{ operationId: "operation.start", callClass: "durableOperationMutation", resultBranches: #["accepted", "rejected", "recovery"], allowedRequestErrors: #[], allowedRecoveryErrors: #[], allowedKnownFailures: #[], allowedAmbiguities: #[], recoveryCoordinates: #[], matrixIds: #[], result: #{ carrierKind: "newDurableOperation", schemaStableId: "result.operation.start" } }) op Start(): void;`,
    ),
    "contract/conflicting-operation-contract",
  );
});

it.each([
  ["identical", "#[]"],
  ["conflicting", '#["state.operation.failed"]'],
])("rejects repeated %s contract profiles on the contract root", async (_kind, secondTerminals) => {
  const diagnostics = await diagnose(
    `@contractRoot @contractProfile(#{ profileId: "packet-e-contract-prototype", terminalStateIds: #[] }) @contractProfile(#{ profileId: "packet-e-contract-prototype", terminalStateIds: ${secondTerminals} }) namespace Slice {}`,
  );
  expect(diagnostics).toEqual([
    expect.objectContaining({
      code: "contract/conflicting-contract-profile",
      target: expect.objectContaining({ kind: "Namespace" }),
    }),
  ]);
});
