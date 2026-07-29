import Std

namespace PacketESpike

def proofMaterialSha256 : String :=
  "1b38211ffa11b8fb25dc87262a65911555e4d6ce4e19a02bfc2a8cf7037beb70"

def translatedCatalogBytesSha256 : String :=
  "0d13ae01d2e1cbd62706e43abc3701272713ceb967ccd43ae05af234022709c1"

def translatedModelBytesSha256 : String :=
  "2f3305d053ecf4e7f3ae1b0d1b0e55e65ced79c5fb481a544251468b7aa46e98"

def translatedCompleteCarrierFields : List String :=
  ["enabled", "gates", "nextState", "outcomes", "postcondition", "effects", "evidence"]

def translatedShardCount : Nat := 2

theorem proofMaterialTranslationBound :
    translatedCatalogBytesSha256 =
      "0d13ae01d2e1cbd62706e43abc3701272713ceb967ccd43ae05af234022709c1" ∧
    translatedModelBytesSha256 =
      "2f3305d053ecf4e7f3ae1b0d1b0e55e65ced79c5fb481a544251468b7aa46e98" ∧
    translatedCompleteCarrierFields =
      ["enabled", "gates", "nextState", "outcomes", "postcondition", "effects", "evidence"] ∧
    translatedShardCount = 2 := by
  exact ⟨rfl, rfl, rfl, rfl⟩

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
    abstractPopulationCarrier population other interleavings =
      completeSemanticCarrier population other interleavings := by
  rfl

theorem populationInductionSymmetry (left right : Nat) :
    left + right = right + left := by
  exact Nat.add_comm left right

abbrev FamilyCoordinate := Nat × Nat × Nat

def incrementFirst (coordinate : FamilyCoordinate) : FamilyCoordinate :=
  (coordinate.1 + 1, coordinate.2.1, coordinate.2.2)

def incrementSecond (coordinate : FamilyCoordinate) : FamilyCoordinate :=
  (coordinate.1, coordinate.2.1 + 1, coordinate.2.2)

def observeCoordinate (coordinate : FamilyCoordinate) : SemanticCarrier :=
  completeSemanticCarrier coordinate.1 coordinate.2.1 coordinate.2.2

theorem mixedFamilyIncrementCommutation (coordinate : FamilyCoordinate) :
    observeCoordinate (incrementFirst (incrementSecond coordinate)) =
      observeCoordinate (incrementSecond (incrementFirst coordinate)) := by
  rfl

inductive CoverageCoordinate (population : Nat) where
  | left (index : Fin population)
  | right (index : Fin population)

def leftRegion {population : Nat} : CoverageCoordinate population → Prop
  | .left _ => True
  | .right _ => False

def rightRegion {population : Nat} : CoverageCoordinate population → Prop
  | .left _ => False
  | .right _ => True

structure CoverageShardSpec where
  family : String
  shardCount : Nat
  cardinalityFormula : String

def symbolicCoverageShardSpec (_population : Nat) : CoverageShardSpec :=
  {
    family := "two-family-symbolic-spike"
    shardCount := 2
    cardinalityFormula := "left=n;right=n;total=2*n"
  }

def enumerateLeft (population : Nat) (index : Fin population) :
    { coordinate : CoverageCoordinate population // leftRegion coordinate } :=
  ⟨.left index, True.intro⟩

def enumerateRight (population : Nat) (index : Fin population) :
    { coordinate : CoverageCoordinate population // rightRegion coordinate } :=
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
    (symbolicCoverageShardSpec population).shardCount = 2 ∧
    (∀ coordinate : CoverageCoordinate population,
      ¬ (leftRegion coordinate ∧ rightRegion coordinate)) ∧
    (∀ coordinate : CoverageCoordinate population,
      leftRegion coordinate ∨ rightRegion coordinate) ∧
    IsBijective (enumerateLeft population) ∧
    IsBijective (enumerateRight population) := by
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
  exact ⟨enumerateLeftBijective population, enumerateRightBijective population⟩

def composeFamilies (primary other : Nat) : SemanticCarrier :=
  {
    enabled := true
    gates := [primary, other]
    nextState := primary + other
    outcomes := [primary + other]
    postcondition := true
    effects := [primary, other]
    evidence := [primary + other]
  }

def applyInterleavings (interleavings : Nat) (carrier : SemanticCarrier) : SemanticCarrier :=
  {
    enabled := carrier.enabled
    gates := carrier.gates
    nextState := carrier.nextState + interleavings
    outcomes := carrier.outcomes
    postcondition := carrier.postcondition
    effects := carrier.effects ++ [interleavings]
    evidence := [interleavings] ++ carrier.evidence
  }

theorem contextualReductionCompleteCarrier
    (primary other interleavings : Nat) :
    applyInterleavings interleavings (composeFamilies primary other) =
      completeSemanticCarrier primary other interleavings := by
  rfl

end PacketESpike
