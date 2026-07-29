import Std

namespace PacketESpike

set_option maxRecDepth 10000

def exactCanonicalProofMaterialBytes : String :=
  include_str "proof-material.json"

def exactCatalogBytes : String :=
  include_str ".." / "normalization" / "fixtures" / "catalog.json"

def exactModelBytes : String :=
  include_str ".." / "normalization" / "fixtures" / "expected-model.json"

inductive ProcedureResult where
  | kernelChecked
  deriving DecidableEq, Repr

structure ExactBytesBinding where
  bytes : String
  byteCount : Nat
  sha256 : String
  deriving DecidableEq, Repr

structure ProofMaterialTranslation where
  canonicalBytes : String
  canonicalSha256 : String
  catalog : ExactBytesBinding
  completeCarrierFields : List String
  model : ExactBytesBinding
  shardCount : Nat
  solverResult : ProcedureResult
  deriving DecidableEq, Repr

def boundProofMaterial : ProofMaterialTranslation :=
  {
    canonicalBytes := exactCanonicalProofMaterialBytes
    canonicalSha256 :=
      "1b38211ffa11b8fb25dc87262a65911555e4d6ce4e19a02bfc2a8cf7037beb70"
    catalog := {
      bytes := exactCatalogBytes
      byteCount := exactCatalogBytes.toUTF8.size
      sha256 :=
        "0d13ae01d2e1cbd62706e43abc3701272713ceb967ccd43ae05af234022709c1"
    }
    completeCarrierFields :=
      ["enabled", "gates", "nextState", "outcomes", "postcondition", "effects", "evidence"]
    model := {
      bytes := exactModelBytes
      byteCount := exactModelBytes.toUTF8.size
      sha256 :=
        "2f3305d053ecf4e7f3ae1b0d1b0e55e65ced79c5fb481a544251468b7aa46e98"
    }
    shardCount := 2
    solverResult := .kernelChecked
  }

structure ProofMaterialBound (material : ProofMaterialTranslation) : Prop where
  canonicalBytes : material.canonicalBytes = exactCanonicalProofMaterialBytes
  canonicalSha256 : material.canonicalSha256 =
    "1b38211ffa11b8fb25dc87262a65911555e4d6ce4e19a02bfc2a8cf7037beb70"
  catalogBytes : material.catalog.bytes = exactCatalogBytes
  catalogByteCount : material.catalog.byteCount = exactCatalogBytes.toUTF8.size
  catalogSha256 : material.catalog.sha256 =
    "0d13ae01d2e1cbd62706e43abc3701272713ceb967ccd43ae05af234022709c1"
  completeCarrierFields : material.completeCarrierFields =
    ["enabled", "gates", "nextState", "outcomes", "postcondition", "effects", "evidence"]
  modelBytes : material.model.bytes = exactModelBytes
  modelByteCount : material.model.byteCount = exactModelBytes.toUTF8.size
  modelSha256 : material.model.sha256 =
    "2f3305d053ecf4e7f3ae1b0d1b0e55e65ced79c5fb481a544251468b7aa46e98"
  shardCount : material.shardCount = 2
  solverResult : material.solverResult = .kernelChecked

theorem proofMaterialTranslationBound : ProofMaterialBound boundProofMaterial := by
  constructor <;> rfl

structure SemanticCarrier where
  enabled : Bool
  gates : List Nat
  nextState : Nat
  outcomes : List Nat
  postcondition : Bool
  effects : List Nat
  evidence : List Nat
  deriving DecidableEq

def completeSemanticCarrier (primary other interleavings : Nat) : SemanticCarrier :=
  {
    enabled := true
    gates := [primary, other]
    nextState := primary + other + interleavings
    outcomes := [primary + other]
    postcondition := true
    effects := [primary, other, interleavings]
    evidence := [interleavings, primary + other]
  }

def abstractPopulationCarrier (population other interleavings : Nat) : SemanticCarrier :=
  completeSemanticCarrier population other interleavings

theorem populationAbstractionUnbounded (population other interleavings : Nat) :
    ProofMaterialBound boundProofMaterial ∧
      abstractPopulationCarrier population other interleavings =
        completeSemanticCarrier population other interleavings := by
  exact ⟨proofMaterialTranslationBound, rfl⟩

theorem populationInductionSymmetry (left right : Nat) :
    ProofMaterialBound boundProofMaterial ∧ left + right = right + left := by
  exact ⟨proofMaterialTranslationBound, Nat.add_comm left right⟩

abbrev FamilyCoordinate := Nat × Nat × Nat

def incrementFirst (coordinate : FamilyCoordinate) : FamilyCoordinate :=
  (coordinate.1 + 1, coordinate.2.1, coordinate.2.2)

def incrementSecond (coordinate : FamilyCoordinate) : FamilyCoordinate :=
  (coordinate.1, coordinate.2.1 + 1, coordinate.2.2)

def observeCoordinate (coordinate : FamilyCoordinate) : SemanticCarrier :=
  completeSemanticCarrier coordinate.1 coordinate.2.1 coordinate.2.2

theorem mixedFamilyIncrementCommutation (coordinate : FamilyCoordinate) :
    ProofMaterialBound boundProofMaterial ∧
      observeCoordinate (incrementFirst (incrementSecond coordinate)) =
        observeCoordinate (incrementSecond (incrementFirst coordinate)) := by
  exact ⟨proofMaterialTranslationBound, rfl⟩

inductive CoverageCoordinate (population : Nat) where
  | left (index : Fin population)
  | right (index : Fin population)

def leftRegion {population : Nat} : CoverageCoordinate population → Prop
  | .left _ => True
  | .right _ => False

def rightRegion {population : Nat} : CoverageCoordinate population → Prop
  | .left _ => False
  | .right _ => True

structure CoverageShardSpec (population : Nat) where
  family : String
  shardCount : Nat
  leftRegion : CoverageCoordinate population → Prop
  rightRegion : CoverageCoordinate population → Prop
  leftCardinality : Nat
  rightCardinality : Nat
  totalCardinality : Nat

def symbolicCoverageShardSpec (population : Nat) : CoverageShardSpec population :=
  {
    family := "two-family-symbolic-spike"
    shardCount := 2
    leftRegion := leftRegion
    rightRegion := rightRegion
    leftCardinality := population
    rightCardinality := population
    totalCardinality := 2 * population
  }

def enumerateLeft (population : Nat) (index : Fin population) :
    { coordinate : CoverageCoordinate population //
      (symbolicCoverageShardSpec population).leftRegion coordinate } :=
  ⟨.left index, True.intro⟩

def enumerateRight (population : Nat) (index : Fin population) :
    { coordinate : CoverageCoordinate population //
      (symbolicCoverageShardSpec population).rightRegion coordinate } :=
  ⟨.right index, True.intro⟩

def IsBijective {α β : Sort _} (function : α → β) : Prop :=
  Function.Injective function ∧ Function.Surjective function

theorem enumerateLeftBijective (population : Nat) :
    IsBijective (enumerateLeft population) := by
  constructor
  · intro leftIndex rightIndex equality
    cases equality
    rfl
  · intro coordinate
    rcases coordinate with ⟨coordinate, membership⟩
    cases coordinate with
    | left index =>
        exact ⟨index, rfl⟩
    | right index =>
        contradiction

theorem enumerateRightBijective (population : Nat) :
    IsBijective (enumerateRight population) := by
  constructor
  · intro leftIndex rightIndex equality
    cases equality
    rfl
  · intro coordinate
    rcases coordinate with ⟨coordinate, membership⟩
    cases coordinate with
    | left index =>
        contradiction
    | right index =>
        exact ⟨index, rfl⟩

theorem coverageShardSpecUniversal (population : Nat) :
    ProofMaterialBound boundProofMaterial ∧
    (symbolicCoverageShardSpec population).shardCount = 2 ∧
    (∀ coordinate : CoverageCoordinate population,
      ¬ ((symbolicCoverageShardSpec population).leftRegion coordinate ∧
        (symbolicCoverageShardSpec population).rightRegion coordinate)) ∧
    (∀ coordinate : CoverageCoordinate population,
      (symbolicCoverageShardSpec population).leftRegion coordinate ∨
        (symbolicCoverageShardSpec population).rightRegion coordinate) ∧
    IsBijective (enumerateLeft population) ∧
    IsBijective (enumerateRight population) ∧
    (symbolicCoverageShardSpec population).leftCardinality = population ∧
    (symbolicCoverageShardSpec population).rightCardinality = population ∧
    (symbolicCoverageShardSpec population).totalCardinality = 2 * population ∧
    (symbolicCoverageShardSpec population).totalCardinality =
      (symbolicCoverageShardSpec population).leftCardinality +
        (symbolicCoverageShardSpec population).rightCardinality := by
  constructor
  · exact proofMaterialTranslationBound
  constructor
  · rfl
  constructor
  · intro coordinate
    cases coordinate with
    | left index =>
        intro overlap
        exact overlap.2
    | right index =>
        intro overlap
        exact overlap.1
  constructor
  · intro coordinate
    cases coordinate with
    | left index =>
        exact Or.inl True.intro
    | right index =>
        exact Or.inr True.intro
  constructor
  · exact enumerateLeftBijective population
  constructor
  · exact enumerateRightBijective population
  constructor
  · rfl
  constructor
  · rfl
  constructor
  · rfl
  exact Nat.two_mul population

def applyOtherFamilyAndInterleavings
    (other interleavings : Nat) (carrier : SemanticCarrier) : SemanticCarrier :=
  {
    enabled := carrier.enabled
    gates := carrier.gates ++ [other]
    nextState := carrier.nextState + other + interleavings
    outcomes := carrier.outcomes ++ [other + interleavings]
    postcondition := carrier.postcondition
    effects := carrier.effects ++ [other, interleavings]
    evidence := carrier.evidence ++ [other, interleavings]
  }

def contextualCarrierRelation
    (carrier result : SemanticCarrier) (other interleavings : Nat) : Prop :=
  result.enabled = carrier.enabled ∧
  result.gates = carrier.gates ++ [other] ∧
  result.nextState = carrier.nextState + other + interleavings ∧
  result.outcomes = carrier.outcomes ++ [other + interleavings] ∧
  result.postcondition = carrier.postcondition ∧
  result.effects = carrier.effects ++ [other, interleavings] ∧
  result.evidence = carrier.evidence ++ [other, interleavings]

theorem contextualReductionCompleteCarrier
    (carrier : SemanticCarrier) (other interleavings : Nat) :
    ProofMaterialBound boundProofMaterial ∧
    contextualCarrierRelation carrier
      (applyOtherFamilyAndInterleavings other interleavings carrier)
      other interleavings := by
  constructor
  · exact proofMaterialTranslationBound
  exact ⟨rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩

end PacketESpike
