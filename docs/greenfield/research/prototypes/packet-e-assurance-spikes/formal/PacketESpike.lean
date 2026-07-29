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

def ProofMaterialBound (material : ProofMaterialTranslation) : Prop :=
  material.canonicalBytes = exactCanonicalProofMaterialBytes ∧
  material.canonicalSha256 =
    "1b38211ffa11b8fb25dc87262a65911555e4d6ce4e19a02bfc2a8cf7037beb70"
  ∧ material.catalog.bytes = exactCatalogBytes
  ∧ material.catalog.byteCount = exactCatalogBytes.toUTF8.size
  ∧ material.catalog.sha256 =
    "0d13ae01d2e1cbd62706e43abc3701272713ceb967ccd43ae05af234022709c1"
  ∧ material.completeCarrierFields =
    ["enabled", "gates", "nextState", "outcomes", "postcondition", "effects", "evidence"]
  ∧ material.model.bytes = exactModelBytes
  ∧ material.model.byteCount = exactModelBytes.toUTF8.size
  ∧ material.model.sha256 =
    "2f3305d053ecf4e7f3ae1b0d1b0e55e65ced79c5fb481a544251468b7aa46e98"
  ∧ material.shardCount = 2
  ∧ material.solverResult = .kernelChecked

theorem proofMaterialTranslationBound : ProofMaterialBound boundProofMaterial := by
  exact ⟨rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩

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

noncomputable def leftRegion {population : Nat} :
    CoverageCoordinate population → Bool :=
  CoverageCoordinate.rec
    (motive := fun _ => Bool)
    (fun _ => true)
    (fun _ => false)

noncomputable def rightRegion {population : Nat} :
    CoverageCoordinate population → Bool :=
  CoverageCoordinate.rec
    (motive := fun _ => Bool)
    (fun _ => false)
    (fun _ => true)

noncomputable def leftIndex? {population : Nat} :
    CoverageCoordinate population → Option (Fin population) :=
  CoverageCoordinate.rec
    (motive := fun _ => Option (Fin population))
    (fun index => some index)
    (fun _ => none)

noncomputable def rightIndex? {population : Nat} :
    CoverageCoordinate population → Option (Fin population) :=
  CoverageCoordinate.rec
    (motive := fun _ => Option (Fin population))
    (fun _ => none)
    (fun index => some index)

structure CoverageShardSpec (population : Nat) where
  family : String
  shardCount : Nat
  leftRegion : CoverageCoordinate population → Bool
  rightRegion : CoverageCoordinate population → Bool
  leftCardinality : Nat
  rightCardinality : Nat
  totalCardinality : Nat

noncomputable def symbolicCoverageShardSpec
    (population : Nat) : CoverageShardSpec population :=
  {
    family := "two-family-symbolic-spike"
    shardCount := 2
    leftRegion := leftRegion
    rightRegion := rightRegion
    leftCardinality := population
    rightCardinality := population
    totalCardinality := 2 * population
  }

noncomputable def enumerateLeft (population : Nat) (index : Fin population) :
    { coordinate : CoverageCoordinate population //
      (symbolicCoverageShardSpec population).leftRegion coordinate = true } :=
  ⟨.left index, rfl⟩

noncomputable def enumerateRight (population : Nat) (index : Fin population) :
    { coordinate : CoverageCoordinate population //
      (symbolicCoverageShardSpec population).rightRegion coordinate = true } :=
  ⟨.right index, rfl⟩

theorem enumerateLeftBijective (population : Nat) :
    Function.Injective (enumerateLeft population) ∧
      Function.Surjective (enumerateLeft population) := by
  constructor
  · intro leftIndex rightIndex equality
    have lifted :=
      congrArg (fun coordinate => leftIndex? coordinate.val) equality
    exact Option.some.inj lifted
  · intro coordinate
    rcases coordinate with ⟨coordinate, membership⟩
    exact CoverageCoordinate.rec
      (motive := fun coordinate =>
        ∀ membership :
            (symbolicCoverageShardSpec population).leftRegion coordinate = true,
          ∃ index, enumerateLeft population index = ⟨coordinate, membership⟩)
      (fun index _ => ⟨index, rfl⟩)
      (fun _ impossible => False.elim (Bool.false_ne_true impossible))
      coordinate
      membership

theorem enumerateRightBijective (population : Nat) :
    Function.Injective (enumerateRight population) ∧
      Function.Surjective (enumerateRight population) := by
  constructor
  · intro leftIndex rightIndex equality
    have lifted :=
      congrArg (fun coordinate => rightIndex? coordinate.val) equality
    exact Option.some.inj lifted
  · intro coordinate
    rcases coordinate with ⟨coordinate, membership⟩
    exact CoverageCoordinate.rec
      (motive := fun coordinate =>
        ∀ membership :
            (symbolicCoverageShardSpec population).rightRegion coordinate = true,
          ∃ index, enumerateRight population index = ⟨coordinate, membership⟩)
      (fun _ impossible => False.elim (Bool.false_ne_true impossible))
      (fun index _ => ⟨index, rfl⟩)
      coordinate
      membership

theorem coverageShardSpecUniversal (population : Nat) :
    ProofMaterialBound boundProofMaterial ∧
    (symbolicCoverageShardSpec population).shardCount = 2 ∧
    (∀ coordinate : CoverageCoordinate population,
      ¬ ((symbolicCoverageShardSpec population).leftRegion coordinate = true ∧
        (symbolicCoverageShardSpec population).rightRegion coordinate = true)) ∧
    (∀ coordinate : CoverageCoordinate population,
      (symbolicCoverageShardSpec population).leftRegion coordinate = true ∨
        (symbolicCoverageShardSpec population).rightRegion coordinate = true) ∧
    (Function.Injective (enumerateLeft population) ∧
      Function.Surjective (enumerateLeft population)) ∧
    (Function.Injective (enumerateRight population) ∧
      Function.Surjective (enumerateRight population)) ∧
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
    exact CoverageCoordinate.rec
      (motive := fun coordinate =>
        ¬ ((symbolicCoverageShardSpec population).leftRegion coordinate = true ∧
          (symbolicCoverageShardSpec population).rightRegion coordinate = true))
      (fun _ overlap => Bool.false_ne_true overlap.2)
      (fun _ overlap => Bool.false_ne_true overlap.1)
      coordinate
  constructor
  · intro coordinate
    exact CoverageCoordinate.rec
      (motive := fun coordinate =>
        (symbolicCoverageShardSpec population).leftRegion coordinate = true ∨
          (symbolicCoverageShardSpec population).rightRegion coordinate = true)
      (fun _ => Or.inl rfl)
      (fun _ => Or.inr rfl)
      coordinate
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
