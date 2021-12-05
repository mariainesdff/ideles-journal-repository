import adeles_R

noncomputable theory
open_locale big_operators classical

variables (R : Type) (K : Type) [comm_ring R] [is_domain R] [is_dedekind_domain R] [field K]
  [algebra R K] [is_fraction_ring R K] (v : maximal_spectrum R)

open set function

/-! Finite ideles of R -/
def finite_idele_group' := units (finite_adele_ring' R K)

instance : topological_space (finite_idele_group' R K) := units.topological_space
instance : group (finite_idele_group' R K) := units.group
instance : topological_group (finite_idele_group' R K) := units.topological_group

--private def map_val : units K → finite_adele_ring' R K := λ x, inj_K R K x.val
--private def map_inv : units K → finite_adele_ring' R K := λ x, inj_K R K x.inv

lemma right_inv (x : units K) : inj_K R K x.val * inj_K R K x.inv = 1 := 
begin
  rw [← inj_K.map_mul, units.val_eq_coe, units.inv_eq_coe_inv, units.mul_inv],
  exact inj_K.map_one R K
end

lemma left_inv (x : units K) : inj_K R K x.inv * inj_K R K x.val = 1 := 
by rw [mul_comm, right_inv]

def inj_units_K : units K → finite_idele_group' R K := 
λ x, ⟨inj_K R K x.val, inj_K R K x.inv, right_inv R K x, left_inv R K x⟩

@[simp]
lemma inj_units_K.map_one : inj_units_K R K 1 = 1 := 
by {rw inj_units_K, simp only [inj_K.map_one], refl,}

@[simp]
lemma inj_units_K.map_mul (x y : units K) : 
  inj_units_K R K (x*y) = (inj_units_K R K x) * (inj_units_K R K y) := 
begin
  rw inj_units_K, ext v,
  simp_rw [units.val_eq_coe, units.coe_mul, units.coe_mk, inj_K.map_mul],
end

def inj_units_K.group_hom : monoid_hom (units K) (finite_idele_group' R K) := 
{ to_fun    := inj_units_K R K,
  map_one' := inj_units_K.map_one R K,
  map_mul'  := inj_units_K.map_mul R K, }

-- We need to assume that the maximal spectrum of R is nonempty (i.e., R is not a field) for this to
-- work 
lemma inj_units_K.injective [inh : inhabited (maximal_spectrum R)] : 
  injective (inj_units_K.group_hom R K) :=
begin
  rw monoid_hom.injective_iff,
  intros x hx,
  rw [inj_units_K.group_hom, monoid_hom.coe_mk, inj_units_K, ← units.eq_iff, units.coe_mk,
    units.val_eq_coe] at hx,
  rw ← units.eq_iff,
  exact (inj_K.injective R K) hx,
end

lemma prod_val_inv_eq_one (x : finite_idele_group' R K) : 
  (x.val.val v) * (x.inv.val v) = 1  :=
begin
  rw [ ← pi.mul_apply, mul_apply_val, units.val_inv, subtype.val_eq_coe, ← one_def,
    subtype.coe_mk, pi.one_apply],
end

lemma v_comp.ne_zero (x : finite_idele_group' R K) :
  (x.val.val v) ≠ 0 := left_ne_zero_of_mul_eq_one (prod_val_inv_eq_one R K v x)

lemma valuation_val_inv (x : finite_idele_group' R K) :
  (valued.v (x.val.val v)) * (valued.v (x.inv.val v)) = 1 :=
by rw [← valuation.map_mul, prod_val_inv_eq_one, valuation.map_one]

lemma valuation_inv (x : finite_idele_group' R K) :
  (valued.v (x.inv.val v)) = (valued.v (x.val.val v))⁻¹ :=
begin
  rw [← mul_one (valued.v (x.val.val v))⁻¹,eq_inv_mul_iff_mul_eq₀, valuation_val_inv],
  { exact (valuation.ne_zero_iff _).mpr (v_comp.ne_zero R K v x) } 
end

lemma restricted_product (x : finite_idele_group' R K) :
  finite ({ v : maximal_spectrum R | (¬ (x.val.val v) ∈ R_v K v) } ∪ 
    { v : maximal_spectrum R | ¬ (x.inv.val v) ∈ R_v K v }) :=
finite.union x.val.property x.inv.property

lemma finite_exponents (x : finite_idele_group' R K) :
  finite { v : maximal_spectrum R | valued.v (x.val.val v) ≠ 1 } :=
begin
  have h_subset : { v : maximal_spectrum R | valued.v (x.val.val v) ≠ 1 } ⊆ 
  { v : maximal_spectrum R | ¬ (x.val.val v) ∈ R_v K v } ∪ 
  { v : maximal_spectrum R | ¬ (x.inv.val v) ∈ R_v K v },
  { intros v hv,
    rw [mem_union, mem_set_of_eq, mem_set_of_eq, K_v.is_integer, K_v.is_integer],
    rw mem_set_of_eq at hv,
    cases (lt_or_gt_of_ne hv) with hlt hgt,
    { right,
      have h_one : (valued.v (x.val.val v)) * (valued.v (x.inv.val v)) = 1 :=
      valuation_val_inv R K v x,
      have h_inv : 1 < (valued.v (x.inv.val v)),
      { have hx : (valued.v (x.val.val v)) ≠ 0,
        { rw [valuation.ne_zero_iff],
          exact left_ne_zero_of_mul_eq_one (prod_val_inv_eq_one R K v x),},
        rw mul_eq_one_iff_inv_eq₀ hx at h_one,
        rw [← h_one, ← with_zero.inv_one, inv_lt_inv₀ (ne.symm zero_ne_one) hx],
        exact hlt, },
      exact not_le.mpr h_inv,},
    { left, exact not_le.mpr hgt, }},
  exact finite.subset (restricted_product R K x) h_subset,
end

def with_zero.to_integer {x : with_zero (multiplicative ℤ )} (hx : x ≠ 0) : ℤ :=
multiplicative.to_add (classical.some (with_zero.ne_zero_iff_exists.mp hx))

def finite_idele.to_add_valuations (x : finite_idele_group' R K) : Π (v : maximal_spectrum R), ℤ :=
λ v, -(with_zero.to_integer ((valuation.ne_zero_iff valued.v).mpr (v_comp.ne_zero R K v x)))

lemma finite_idele.to_add_valuations.map_one : 
  finite_idele.to_add_valuations R K (1 : finite_idele_group' R K) = 
    λ (v : maximal_spectrum R), (0 : ℤ) :=
begin
  rw finite_idele.to_add_valuations,
  ext v,
  rw [with_zero.to_integer, ← to_add_one, ← to_add_inv],
  apply congr_arg multiplicative.to_add,
  rw [inv_eq_one, ← with_zero.coe_inj, classical.some_spec
  (with_zero.to_integer._proof_1 (finite_idele.to_add_valuations._proof_1 R K 1 v))],
  exact valuation.map_one _,
end

lemma finite_idele.to_add_valuations.map_mul (x y : finite_idele_group' R K) : 
finite_idele.to_add_valuations R K (x * y) = 
(finite_idele.to_add_valuations R K x) + (finite_idele.to_add_valuations R K y) :=
begin
  rw [finite_idele.to_add_valuations, finite_idele.to_add_valuations, 
    finite_idele.to_add_valuations],
  ext v,
  simp only [pi.add_apply],
  rw [← neg_add, neg_inj, with_zero.to_integer, with_zero.to_integer, with_zero.to_integer,
    ← to_add_mul],
  apply congr_arg,
  rw [← with_zero.coe_inj, with_zero.coe_mul,
    classical.some_spec (with_zero.to_integer._proof_1 _),
    classical.some_spec (with_zero.to_integer._proof_1 _),
    classical.some_spec (with_zero.to_integer._proof_1 _)],
  exact valuation.map_mul valued.v _ _,
end

lemma finite_add_support (x : finite_idele_group' R K ) : 
  ∀ᶠ (v : maximal_spectrum R) in filter.cofinite, finite_idele.to_add_valuations R K x v = 0 := 
begin
  have h := finite_exponents R K x,
  rw finite_idele.to_add_valuations,
  simp_rw [neg_eq_zero, with_zero.to_integer],
  have h_subset : {v : maximal_spectrum R | ¬multiplicative.to_add (classical.some 
    (with_zero.to_integer._proof_1 ((valued.v.ne_zero_iff ).mpr (v_comp.ne_zero R K v x)))) = 0} 
    ⊆ {v : maximal_spectrum R | valued.v (x.val.val v) ≠ 1},
  { intros v hv,
    set y := (classical.some (with_zero.to_integer._proof_1 
      ((valued.v.ne_zero_iff ).mpr (v_comp.ne_zero R K v x)))) with hy,
    rw mem_set_of_eq,
    by_contradiction h,
    have y_spec := classical.some_spec
      (with_zero.to_integer._proof_1 ((valued.v.ne_zero_iff ).mpr (v_comp.ne_zero R K v x))),
    rw [← hy, h, ← with_zero.coe_one, with_zero.coe_inj] at y_spec,
    rw [← to_add_one, mem_set_of_eq, ← hy, y_spec] at hv,
    exact hv (eq.refl _) },
  exact finite.subset (finite_exponents R K x) h_subset
end

lemma finite_support (x : finite_idele_group' R K ) : (mul_support (λ (v : maximal_spectrum R), 
  (v.val.as_ideal : 
    fractional_ideal (non_zero_divisors R) K) ^ finite_idele.to_add_valuations R K x v)).finite := 
begin
  have h_subset :
    {v : maximal_spectrum R | (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K) ^ 
      finite_idele.to_add_valuations R K x v ≠ 1} ⊆
    { v : maximal_spectrum R | valued.v (x.val.val v) ≠ 1 },
  { intros v,
    rw mem_set_of_eq, rw mem_set_of_eq,
    contrapose!,
    intro hv,
    suffices : finite_idele.to_add_valuations R K x v = 0,
    { rw this, exact zpow_zero _ },
    rw finite_idele.to_add_valuations,
    simp only [with_zero.to_integer],
    rw [← to_add_one, ← to_add_inv],
    apply congr_arg,
    rw [inv_eq_one, ← with_zero.coe_inj, classical.some_spec (with_zero.to_integer._proof_1 _)],
    exact hv, },
  exact finite.subset (finite_exponents R K x) h_subset,
end

lemma finite_support' (x : finite_idele_group' R K ) : (mul_support (λ (v : maximal_spectrum R), 
  (v.val.as_ideal : 
    fractional_ideal (non_zero_divisors R) K) ^ -finite_idele.to_add_valuations R K x v)).finite
:= 
begin
  have h : {v : maximal_spectrum R | (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K) ^ 
    -finite_idele.to_add_valuations R K x v ≠ 1} =
    {v : maximal_spectrum R | (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K) ^ 
      finite_idele.to_add_valuations R K x v ≠ 1},
  { ext v,
    rw [mem_set_of_eq, mem_set_of_eq, ne.def, ne.def, zpow_neg₀, inv_eq_one₀], },
  rw [mul_support, h],
  exact finite_support R K x,
end

def map_to_fractional_ideals.val :
  (finite_idele_group' R K) → (fractional_ideal (non_zero_divisors R) K) := λ x,
∏ᶠ (v : maximal_spectrum R), (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K)^
  (finite_idele.to_add_valuations R K x v)
  
def map_to_fractional_ideals.inv :
  (finite_idele_group' R K) → (fractional_ideal (non_zero_divisors R) K) := λ x,
∏ᶠ (v : maximal_spectrum R), (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K)^
  (-finite_idele.to_add_valuations R K x v)

lemma finite_idele.to_add_valuations.mul_inv (x : finite_idele_group' R K): 
  map_to_fractional_ideals.val R K x * map_to_fractional_ideals.inv R K x = 1 := 
begin
  rw [map_to_fractional_ideals.val, map_to_fractional_ideals.inv],
  dsimp only,
  rw ← finprod_mul_distrib (finite_support R K x) (finite_support' R K x),
  rw ← finprod_one,
  apply finprod_congr ,
  intro v,
  rw ← zpow_add₀,
  rw [add_right_neg, zpow_zero],
  { rw [ne.def, fractional_ideal.coe_ideal_eq_zero_iff],
      exact v.property },
end

lemma finite_idele.to_add_valuations.inv_mul (x : finite_idele_group' R K): 
  map_to_fractional_ideals.inv R K x * map_to_fractional_ideals.val R K x = 1 := 
begin
  rw mul_comm,
  exact finite_idele.to_add_valuations.mul_inv R K x,
end

def map_to_fractional_ideals.def :
  (finite_idele_group' R K) → (units (fractional_ideal (non_zero_divisors R) K)) := λ x,
⟨map_to_fractional_ideals.val R K x, map_to_fractional_ideals.inv R K x, 
  finite_idele.to_add_valuations.mul_inv R K x, finite_idele.to_add_valuations.inv_mul R K x⟩

def map_to_fractional_ideals : monoid_hom
  (finite_idele_group' R K)  (units (fractional_ideal (non_zero_divisors R) K)) := 
{ to_fun := map_to_fractional_ideals.def R K,
  map_one' := by {
    rw map_to_fractional_ideals.def,
    dsimp only,
    rw [← units.eq_iff, units.coe_mk, units.coe_one, map_to_fractional_ideals.val],
    simp_rw [finite_idele.to_add_valuations.map_one, zpow_zero, finprod_one],
  },
  map_mul' := λ x y,
  begin
    rw [map_to_fractional_ideals.def, ← units.eq_iff, units.coe_mul, units.coe_mk, units.coe_mk, 
      units.coe_mk, map_to_fractional_ideals.val], 
    dsimp only,
    rw finite_idele.to_add_valuations.map_mul,
    simp_rw pi.add_apply,
    rw ← finprod_mul_distrib (finite_support R K x) (finite_support R K y),
    apply finprod_congr,
    intro v,
    rw zpow_add₀,
    { rw [ne.def, fractional_ideal.coe_ideal_eq_zero_iff],
      exact v.property },
  end}

variables {R K}
lemma associates.finite_factors (I : ideal R) (hI : I ≠ 0) :
  ∀ᶠ (v : maximal_spectrum R) in filter.cofinite,
  ((associates.mk v.val.as_ideal).count (associates.mk I).factors : ℤ) = 0 :=
begin
  have h_supp : {v : maximal_spectrum R |
    ¬((associates.mk v.val.as_ideal).count (associates.mk I).factors : ℤ) = 0} =
    { v : maximal_spectrum R | v.val.as_ideal ∣ I },
  { ext v,
    rw mem_set_of_eq, rw mem_set_of_eq,
    rw [int.coe_nat_eq_zero, subtype.val_eq_coe],
    exact associates.count_ne_zero_iff_dvd hI (ideal.irreducible_of_maximal v),},
  rw [filter.eventually_cofinite, h_supp],
  exact ideal.finite_factors hI,
end

lemma val_property {a : Π v : maximal_spectrum R, K_v K v}
  (ha : ∀ᶠ v : maximal_spectrum R in filter.cofinite, valued.v (a v) = 1)
  (h_ne_zero : ∀ v : maximal_spectrum R, a v ≠ 0) :
  ∀ᶠ v : maximal_spectrum R in filter.cofinite, a v ∈ R_v K v :=
begin
  rw filter.eventually_cofinite at ha ⊢,
  simp_rw K_v.is_integer,
  have h_subset : {x : maximal_spectrum R | ¬valued.v (a x) ≤ 1} ⊆ 
    {x : maximal_spectrum R | ¬valued.v (a x) = 1},
  { intros v hv,
    exact ne_of_gt (not_le.mp hv), },
  exact finite.subset ha h_subset,
end

lemma inv_property {a : Π v : maximal_spectrum R, K_v K v}
  (ha : ∀ᶠ v : maximal_spectrum R in filter.cofinite, valued.v (a v) = 1)
  (h_ne_zero : ∀ v : maximal_spectrum R, a v ≠ 0) :
  ∀ᶠ v : maximal_spectrum R in filter.cofinite, (a v)⁻¹ ∈ R_v K v :=
begin
  rw filter.eventually_cofinite at ha ⊢,
  simp_rw [K_v.is_integer, not_le],
  have h_subset : {x : maximal_spectrum R | 1 < valued.v (a x)⁻¹} ⊆ 
    {x : maximal_spectrum R | ¬valued.v (a x) = 1},
  { intros v hv,
    rw [mem_set_of_eq, valuation.map_inv] at hv ,
    rw [mem_set_of_eq, ← inv_inj₀, inv_one],
    exact ne_of_gt hv, },
  exact finite.subset ha h_subset,
end

lemma right_inv' {a : Π v : maximal_spectrum R, K_v K v}
  (ha : ∀ᶠ v : maximal_spectrum R in filter.cofinite, valued.v (a v) = 1)
  (h_ne_zero : ∀ v : maximal_spectrum R, a v ≠ 0)  :
  (⟨a, val_property ha h_ne_zero⟩ : finite_adele_ring' R K) *
  ⟨(λ v : maximal_spectrum R, (a v)⁻¹), inv_property ha h_ne_zero⟩ = 1 := 
begin
  ext v,
  unfold_projs,
  simp only [mul'],
  rw [subtype.coe_mk, subtype.coe_mk, pi.mul_apply, if_neg (h_ne_zero v)],
  apply mul_hat_inv_cancel,
  exact h_ne_zero v,
end

lemma left_inv' {a : Π v : maximal_spectrum R, K_v K v}
  (ha : ∀ᶠ v : maximal_spectrum R in filter.cofinite, valued.v (a v) = 1)
  (h_ne_zero : ∀ v : maximal_spectrum R, a v ≠ 0) :
  (⟨(λ v : maximal_spectrum R, (a v)⁻¹), inv_property ha h_ne_zero⟩ : finite_adele_ring' R K) *
  ⟨a, val_property ha h_ne_zero⟩ = 1 := 
by { rw mul_comm, exact right_inv' ha h_ne_zero}

def idele.mk (a : Π v : maximal_spectrum R, K_v K v)
  (ha : ∀ᶠ v : maximal_spectrum R in filter.cofinite, valued.v (a v) = 1)
  (h_ne_zero : ∀ v : maximal_spectrum R, a v ≠ 0) :
  finite_idele_group' R K :=
⟨⟨a, val_property ha h_ne_zero⟩, ⟨(λ v : maximal_spectrum R, (a v)⁻¹), inv_property ha h_ne_zero⟩,
    right_inv' ha h_ne_zero, left_inv' ha h_ne_zero⟩

lemma idele.finite_mul_support {I : ideal R} (hI : I ≠ 0):
  (mul_support (λ (v : maximal_spectrum R), 
  (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K)^
  ((associates.mk v.val.as_ideal).count (associates.mk I).factors : ℤ))).finite := 
begin
  have h_subset : {v : maximal_spectrum R | 
    (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K) ^
    ((associates.mk v.val.as_ideal).count (associates.mk I).factors : ℤ) ≠ 1} ⊆ 
    {v : maximal_spectrum R | 
    ((associates.mk v.val.as_ideal).count (associates.mk I).factors : ℤ) ≠ 0},
  { intros v hv,
    rw mem_set_of_eq at hv ⊢,
    intro h_zero,
    have hv' : (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K)^
      ((associates.mk v.val.as_ideal).count (associates.mk I).factors : ℤ) = 1,
    { rw [h_zero, zpow_zero _],},
    exact hv hv', },
  exact finite.subset (filter.eventually_cofinite.mp (associates.finite_factors I hI)) h_subset,
end

lemma idele.finite_mul_support' (I : ideal R) (hI : I ≠ 0):
  (mul_support (λ (v : maximal_spectrum R), 
  v.val.as_ideal^(associates.mk v.val.as_ideal).count (associates.mk I).factors)).finite := 
begin
  have h_subset : {v : maximal_spectrum R | 
    v.val.as_ideal^
    (associates.mk v.val.as_ideal).count (associates.mk I).factors ≠ 1} ⊆ 
    {v : maximal_spectrum R | 
    ((associates.mk v.val.as_ideal).count (associates.mk I).factors : ℤ) ≠ 0},
  { intros v hv,
    rw mem_set_of_eq at hv ⊢,
    intro h_zero,
    rw int.coe_nat_eq_zero at h_zero,
    have hv' : v.val.as_ideal^
      (associates.mk v.val.as_ideal).count (associates.mk I).factors = 1,
    { rw [h_zero, pow_zero _],},
    exact hv hv', },
  exact finite.subset (filter.eventually_cofinite.mp (associates.finite_factors I hI)) h_subset,
end

lemma idele.finite_mul_support_inv {I : ideal R} (hI : I ≠ 0):
  (mul_support (λ (v : maximal_spectrum R), 
  (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K)^
  -((associates.mk v.val.as_ideal).count (associates.mk I).factors : ℤ))).finite := 
begin
  rw mul_support, 
  simp_rw [zpow_neg₀, ne.def, inv_eq_one₀],
  exact idele.finite_mul_support hI,
end

lemma map_to_fractional_ideals.inv_eq_inv (x : finite_idele_group' R K)
  (I : units (fractional_ideal (non_zero_divisors R) K))
  (hxI : map_to_fractional_ideals.val R K (x) = I.val) : 
  map_to_fractional_ideals.inv R K (x) = I.inv := 
begin
  have h_inv : I.val * (map_to_fractional_ideals.inv R K (x)) = 1,
  { rw ← hxI, exact finite_idele.to_add_valuations.mul_inv R K _ },
  exact eq_comm.mp (units.inv_eq_of_mul_eq_one h_inv),
end

-- associates lemmas
 lemma associates.count_self {α : Type*} [comm_cancel_monoid_with_zero α] 
  [unique_factorization_monoid α] [nontrivial α] [dec : decidable_eq α]
  [dec' : decidable_eq (associates α)] {p : associates α} (hp : irreducible p) : 
  p.count p.factors = 1 := 
begin
  rw [← pow_one p, associates.factors_prime_pow hp, pow_one, associates.count_some hp],
  exact multiset.count_singleton_self _,
end

lemma associates.factors_eq_none_iff_zero {α : Type*} [comm_cancel_monoid_with_zero α] 
  [unique_factorization_monoid α] [nontrivial α] [dec : decidable_eq α]
  [dec' : decidable_eq (associates α)] {a : associates α} : 
  a.factors = option.none ↔ a = 0 :=
begin
  split; intro h,
    { rw [← associates.factors_prod a, associates.factor_set.prod_eq_zero_iff], exact h,},
    { rw h, exact associates.factors_0 }
end

lemma associates.factors_eq_some_iff_ne_zero {α : Type*} [comm_cancel_monoid_with_zero α] 
  [unique_factorization_monoid α] [nontrivial α] [dec : decidable_eq α]
  [dec' : decidable_eq (associates α)] {a : associates α} : 
  (∃ (s : multiset {p : associates α // irreducible p}), a.factors = some s) ↔ a ≠ 0 :=
begin
  rw [← option.is_some_iff_exists, ← option.ne_none_iff_is_some, ne.def, ne.def,
    associates.factors_eq_none_iff_zero],
end

theorem associates.eq_factors_of_eq_counts {α : Type*} [comm_cancel_monoid_with_zero α] 
  [unique_factorization_monoid α] [nontrivial α] [dec : decidable_eq α]
  [dec' : decidable_eq (associates α)]{a b : associates α} (ha : a ≠ 0) (hb : b ≠ 0)
  (h :  ∀ (p : associates α) (hp : irreducible p), p.count a.factors = p.count b.factors) :
  a.factors = b.factors := 
begin
  obtain ⟨sa, h_sa⟩ := associates.factors_eq_some_iff_ne_zero.mpr ha,
  obtain ⟨sb, h_sb⟩ := associates.factors_eq_some_iff_ne_zero.mpr hb,
  rw [h_sa, h_sb] at h ⊢,
  rw option.some_inj,
  have h_count :  ∀ (p : associates α) (hp : irreducible p), sa.count ⟨p, hp⟩ = sb.count ⟨p, hp⟩,
  { intros p hp, rw [← associates.count_some, ← associates.count_some, h p hp], },
  apply multiset.to_finsupp.injective,
  ext ⟨p, hp⟩,
  rw [multiset.to_finsupp_apply, multiset.to_finsupp_apply, h_count p hp],
end

theorem associates.eq_of_eq_counts {α : Type*} [comm_cancel_monoid_with_zero α] [nontrivial α]
  [unique_factorization_monoid α] [dec : decidable_eq α] [dec' : decidable_eq (associates α)]
  {a b : associates α} (ha : a ≠ 0) (hb  : b ≠ 0)
  (h :  ∀ (p : associates α), irreducible p → p.count a.factors = p.count b.factors) : a = b := 
associates.eq_of_factors_eq_factors (associates.eq_factors_of_eq_counts ha hb h)

lemma finprod_eq_finprod_cond {α : Type*} {N : Type*} [comm_monoid N] {f : α → N}
  (hf : finite (mul_support f)) : ∏ᶠ i, f i = (∏ᶠ i ∈ (mul_support f), f i)  := 
begin
  rw [finprod_eq_prod f hf, eq_comm],
  apply finprod_cond_eq_prod_of_cond_iff, 
  intros a fa,
  rw finite.mem_to_finset,
end

lemma finprod_mem_dvd' {α : Type*} {N : Type*} [comm_monoid N] {f : α → N} (a : α)
  (hf : finite (mul_support f)) :
  f a * (∏ᶠ i ∈ (mul_support f) \ {a}, f i) = ∏ᶠ i, f i  := 
begin
  by_cases ha : a ∈ mul_support f,
  { have h_inter : (∏ᶠ (i : α) (H : i ∈ {a}), f i) = 
      (∏ᶠ (i : α) (H : i ∈ mul_support f ∩ {a}), f i),
    { rw inter_eq_right_iff_subset.mpr (singleton_subset_iff.mpr ha), },
    rw [finprod_eq_finprod_cond hf, ← @finprod_mem_singleton α N _ f a, h_inter],
    exact @finprod_mem_inter_mul_diff _ _ _ f (mul_support f) {a} hf, },
  { have h_inter : f a = (∏ᶠ (i : α) (H : i ∈ mul_support f ∩ {a}), f i),
    { rw [nmem_mul_support.mp ha, inter_singleton_eq_empty.mpr ha, finprod_mem_empty], },
    rw [finprod_eq_finprod_cond hf, h_inter],
    exact @finprod_mem_inter_mul_diff _ _ _ f (mul_support f) {a} hf, },
end

lemma prime.exists_mem_finprod_dvd {α : Type*} {N : Type*} [comm_monoid_with_zero N] {f : α → N} 
  {p : N} (hp : prime p) (hf : finite (mul_support f)) :
  p ∣  ∏ᶠ i, f i →  ∃ (a : α), p ∣ f a := 
begin
  rw finprod_eq_prod _ hf,
  intro h,
  obtain ⟨a, -, ha_dvd⟩ := prime.exists_mem_finset_dvd hp h,
  exact ⟨a, ha_dvd⟩,
end

lemma ideal.finprod_not_dvd (I : ideal R) (hI : I ≠ 0) : 
¬ (v.val.as_ideal)^
  ((associates.mk v.val.as_ideal).count (associates.mk I).factors + 1) ∣
    (∏ᶠ (v : maximal_spectrum R), (v.val.as_ideal)^
      (associates.mk v.val.as_ideal).count (associates.mk I).factors) :=
begin
  have h_ne_zero : v.val.as_ideal ^
    (associates.mk v.val.as_ideal).count (associates.mk I).factors ≠ 0 := pow_ne_zero _ v.property,
  rw [← finprod_mem_dvd' v (idele.finite_mul_support' I hI), pow_add, pow_one],
  intro h_contr,
  rw mul_dvd_mul_iff_left h_ne_zero at h_contr,
  have hv_prime : prime v.val.as_ideal := ideal.prime_of_is_prime v.property v.val.property,
  have h_finite : finite (mul_support (λ (v : maximal_spectrum R), v.val.as_ideal^
    (associates.mk v.val.as_ideal).count (associates.mk I).factors) \ {v}),
  { apply finite.subset (idele.finite_mul_support' I hI) (diff_subset _ _), },
  rw finprod_mem_eq_finite_to_finset_prod _ h_finite at h_contr,
  obtain ⟨w, hw, hvw'⟩ := prime.exists_mem_finset_dvd hv_prime h_contr,
  have hw_prime : prime w.val.as_ideal := ideal.prime_of_is_prime w.property w.val.property,
  rw [finite.mem_to_finset, mem_diff, mem_singleton_iff] at hw,
  have hvw := prime.dvd_of_dvd_pow hv_prime hvw',
  rw [prime.dvd_prime_iff_associated hv_prime hw_prime, associated_iff_eq] at hvw,
  have hv' : v.val.as_ideal = v.val.val := rfl,
  have hw' : w.val.as_ideal = w.val.val := rfl,
  rw [hv', hw', subtype.val_eq_coe, subtype.val_eq_coe, subtype.val_eq_coe, subtype.val_eq_coe]
    at hvw, 
  exact hw.2 (eq.symm (subtype.coe_injective(subtype.coe_injective hvw))), 
end

lemma ideal.finprod_count_ne_zero (I : ideal R) :
  associates.mk (∏ᶠ (v : maximal_spectrum R), v.val.as_ideal ^ 
    (associates.mk v.val.as_ideal).count (associates.mk I).factors) ≠ 0 := 
begin
  rw [associates.mk_ne_zero, finprod_def],
  split_ifs,
  { rw finset.prod_ne_zero_iff,
    intros v hv,
    apply pow_ne_zero _ v.property, },
  { exact one_ne_zero, }
end

lemma ideal.finprod_count (I : ideal R) (hI : I ≠ 0) :
(associates.mk v.val.as_ideal).count (associates.mk (∏ᶠ (v : maximal_spectrum R), (v.val.as_ideal)^
    (associates.mk v.val.as_ideal).count (associates.mk I).factors)).factors = 
    (associates.mk v.val.as_ideal).count (associates.mk I).factors :=
begin
  have h_ne_zero := ideal.finprod_count_ne_zero I,
  have hv : irreducible (associates.mk v.val.as_ideal) := associates.irreducible_of_maximal v,
  have h_dvd := finprod_mem_dvd _ (idele.finite_mul_support' I hI),
  have h_not_dvd := ideal.finprod_not_dvd v I hI,
  rw [← associates.mk_dvd_mk, associates.dvd_eq_le, associates.mk_pow,
    associates.prime_pow_dvd_iff_le h_ne_zero hv] at h_dvd h_not_dvd,
  rw not_le at h_not_dvd,
  apply nat.eq_of_le_of_lt_succ h_dvd h_not_dvd,
end

/- lemma ideal.finprod_count' (exps : Π v : maximal_spectrum R, ℕ) 
(h_exps : ∀ᶠ (v : maximal_spectrum R) in filter.cofinite, exps v = 0):
(associates.mk v.val.as_ideal).count (associates.mk (∏ᶠ (v : maximal_spectrum R), (v.val.as_ideal)^
    (exps v))).factors = exps v :=
begin
  sorry,
  /- have h_ne_zero := ideal.finprod_ne_zero I,
  have hv : irreducible (associates.mk v.val.as_ideal) := associates.irreducible_of_maximal v,
  have h_dvd := finprod_mem_dvd _ (idele.finite_mul_support' I hI),
  have h_not_dvd := ideal.finprod_not_dvd v I hI,
  rw [← associates.mk_dvd_mk, associates.dvd_eq_le, associates.mk_pow,
    associates.prime_pow_dvd_iff_le h_ne_zero hv] at h_dvd h_not_dvd,
  rw not_le at h_not_dvd,
  apply nat.eq_of_le_of_lt_succ h_dvd h_not_dvd, -/
end -/

lemma ideal.factorization (I : ideal R) (hI : I ≠ 0) :
  ∏ᶠ (v : maximal_spectrum R), (v.val.as_ideal)^
    (associates.mk v.val.as_ideal).count (associates.mk I).factors = I := 
begin
  rw [← associated_iff_eq, ← associates.mk_eq_mk_iff_associated],
  apply associates.eq_of_eq_counts,
  { apply ideal.finprod_count_ne_zero I },
  { apply associates.mk_ne_zero.mpr hI},
  intros v hv,
  obtain ⟨J, hJv⟩ := associates.exists_rep v,
  rw [← hJv, associates.irreducible_mk] at hv,
  have hJ_ne_zero : J ≠ 0 := irreducible.ne_zero hv,
  rw unique_factorization_monoid.irreducible_iff_prime at hv,
  rw ← hJv,
  apply ideal.finprod_count ⟨⟨J, ideal.is_prime_of_prime hv⟩, hJ_ne_zero⟩ I hI,
end

variables {A : Type*} [comm_ring A] (B : submonoid A) (C : Type*) [comm_ring C]
variables [algebra A C]
lemma fractional_ideal.coe_pow (I : ideal A) (n : ℕ) : 
  (↑(I^n) : fractional_ideal B C) = (↑I)^n :=
begin
  induction n with n ih,
  { simp, },
  { simp [pow_succ, ih], },
end

variable [is_localization B C]
lemma fractional_ideal.coe_finprod {α : Type*} {f : α → ideal A} (hB : B ≤ non_zero_divisors A) :
  ((∏ᶠ a : α, f a : ideal A) : fractional_ideal B C) = ∏ᶠ a : α, (f a : fractional_ideal B C)  := 
begin
  have h_coe : ⇑(fractional_ideal.coe_ideal_hom B C).to_monoid_hom = coe := rfl,
  rw [← h_coe,
    monoid_hom.map_finprod_of_injective (fractional_ideal.coe_ideal_hom B C).to_monoid_hom, h_coe],
  exact fractional_ideal.coe_to_fractional_ideal_injective hB,
end

lemma ideal.factorization_coe (I : ideal R) (hI : I ≠ 0) :
  ∏ᶠ (v : maximal_spectrum R), (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K)^
    ((associates.mk v.val.as_ideal).count (associates.mk I).factors : ℤ) = I := 
begin
  conv_rhs{rw ← ideal.factorization I hI}, 
  rw fractional_ideal.coe_finprod,
  simp_rw [fractional_ideal.coe_pow, zpow_coe_nat],
  { exact le_refl _ }
end

lemma finprod_inv_distrib₀ {α : Type*} {G : Type*} [comm_group_with_zero G] (f : α → G) :
  ∏ᶠ x, (f x)⁻¹ = (∏ᶠ x, f x)⁻¹ :=
begin
  have h_supp : mul_support (λ (i : α), (f i)⁻¹) = mul_support f,
  { simp only [mul_support, ne.def, inv_eq_one₀], },
  rw finprod_def,
  split_ifs with hf,
  { rw [finprod_def, ← h_supp, dif_pos hf],
    exact finset.prod_inv_distrib',},
  { rw [finprod_def, ← h_supp, dif_neg hf, inv_one], }
end

lemma fractional_ideal.ideal_factor_ne_zero {I : fractional_ideal (non_zero_divisors R) K}
  (hI : I ≠ 0) {a : R} {J : ideal R} 
  (haJ : I = fractional_ideal.span_singleton (non_zero_divisors R) ((algebra_map R K) a)⁻¹ * ↑J) :
  J ≠ 0 :=
begin
  intro h, 
  rw [h, ideal.zero_eq_bot, fractional_ideal.coe_to_fractional_ideal_bot, mul_zero] at haJ, 
  exact hI haJ,
end

lemma fractional_ideal.constant_factor_ne_zero {I : fractional_ideal (non_zero_divisors R) K}
  (hI : I ≠ 0) {a : R} {J : ideal R} 
  (haJ : I = fractional_ideal.span_singleton (non_zero_divisors R) ((algebra_map R K) a)⁻¹ * ↑J) :
  (ideal.span{a} : ideal R) ≠ 0 :=
begin
  intro h,
  rw [ideal.zero_eq_bot, ideal.span_singleton_eq_bot] at h,
  rw [h, ring_hom.map_zero, inv_zero, fractional_ideal.span_singleton_zero, zero_mul] at haJ,
  exact hI haJ,
end

lemma fractional_ideal.factorization (I : fractional_ideal (non_zero_divisors R) K) (hI : I ≠ 0) 
  {a : R} {J : ideal R} 
  (haJ : I = fractional_ideal.span_singleton (non_zero_divisors R) ((algebra_map R K) a)⁻¹ * ↑J) :
  ∏ᶠ (v : maximal_spectrum R), (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K)^
    ((associates.mk v.val.as_ideal).count (associates.mk J).factors - 
    (associates.mk v.val.as_ideal).count (associates.mk (ideal.span{a})).factors : ℤ) = I := 
begin
  have hJ_ne_zero : J ≠ 0 := fractional_ideal.ideal_factor_ne_zero hI haJ,
  have hJ := ideal.factorization_coe J hJ_ne_zero,
  have ha_ne_zero : ideal.span{a} ≠ 0 := fractional_ideal.constant_factor_ne_zero hI haJ,
  have ha := ideal.factorization_coe (ideal.span{a} : ideal R) ha_ne_zero,
  rw [haJ, ← fractional_ideal.div_span_singleton, fractional_ideal.div_eq_mul_inv,
    ← fractional_ideal.coe_ideal_span_singleton, ← hJ, ← ha, ← finprod_inv_distrib₀],
  simp_rw ← zpow_neg₀,
  rw ← finprod_mul_distrib,
  apply finprod_congr,
  intro v,
  rw [← zpow_add₀ ((@fractional_ideal.coe_ideal_ne_zero_iff R _ K _ _ _ _).mpr v.property),
    sub_eq_add_neg],
  apply idele.finite_mul_support hJ_ne_zero, 
  apply idele.finite_mul_support_inv ha_ne_zero, 
  { apply_instance },
end

variables (K)
def fractional_ideal.count (I : fractional_ideal (non_zero_divisors R) K) : ℤ := 
dite (I = 0) (λ (hI : I = 0), 0) (λ hI : ¬ I = 0, 
let a := classical.some (fractional_ideal.exists_eq_span_singleton_mul I) in let 
J := classical.some (classical.some_spec (fractional_ideal.exists_eq_span_singleton_mul I))
in ((associates.mk v.val.as_ideal).count (associates.mk J).factors - 
    (associates.mk v.val.as_ideal).count (associates.mk (ideal.span{a})).factors : ℤ))

lemma fractional_ideal.count_well_defined  {I : fractional_ideal (non_zero_divisors R) K}
  (hI : I ≠ 0)  {a : R} {J : ideal R} 
  (h_aJ : I = fractional_ideal.span_singleton (non_zero_divisors R) ((algebra_map R K) a)⁻¹ * ↑J) :
  fractional_ideal.count K v I = ((associates.mk v.val.as_ideal).count (associates.mk J).factors - 
    (associates.mk v.val.as_ideal).count (associates.mk (ideal.span{a})).factors : ℤ) :=
begin
  set a₁ := classical.some (fractional_ideal.exists_eq_span_singleton_mul I) with h_a₁,
  set J₁ := classical.some (classical.some_spec (fractional_ideal.exists_eq_span_singleton_mul I))
    with h_J₁,
  have h_a₁J₁ : I = fractional_ideal.span_singleton (non_zero_divisors R) ((algebra_map R K) a₁)⁻¹ *
    ↑J₁ :=
  (classical.some_spec (classical.some_spec (fractional_ideal.exists_eq_span_singleton_mul I))).2,
  have h_a₁_ne_zero : a₁ ≠ 0 :=
  (classical.some_spec (classical.some_spec (fractional_ideal.exists_eq_span_singleton_mul I))).1,
  have h_J₁_ne_zero : J₁ ≠ 0 := fractional_ideal.ideal_factor_ne_zero hI h_a₁J₁,
  have h_a_ne_zero : ideal.span{a} ≠ 0 := fractional_ideal.constant_factor_ne_zero hI h_aJ,
  have h_J_ne_zero : J ≠ 0 := fractional_ideal.ideal_factor_ne_zero hI h_aJ,
  have h_a₁' : fractional_ideal.span_singleton (non_zero_divisors R) ((algebra_map R K) a₁) ≠ 0,
  { rw [ne.def, fractional_ideal.span_singleton_eq_zero_iff, ← (algebra_map R K).map_zero,
      injective.eq_iff (is_localization.injective K (le_refl (non_zero_divisors R)))],
    exact h_a₁_ne_zero,},
  have h_a' : fractional_ideal.span_singleton (non_zero_divisors R) ((algebra_map R K) a) ≠ 0,
  { rw [ne.def, fractional_ideal.span_singleton_eq_zero_iff, ← (algebra_map R K).map_zero,
      injective.eq_iff (is_localization.injective K (le_refl (non_zero_divisors R)))],
    rw [ne.def, ideal.zero_eq_bot, ideal.span_singleton_eq_bot] at h_a_ne_zero,
    exact h_a_ne_zero,},
  have hv : irreducible (associates.mk v.val.as_ideal),
  { rw associates.irreducible_mk,
    exact ideal.irreducible_of_maximal v,},
  rw [h_a₁J₁, ← fractional_ideal.div_span_singleton, ← fractional_ideal.div_span_singleton,
    div_eq_div_iff h_a₁' h_a', ← fractional_ideal.coe_ideal_span_singleton,
    ← fractional_ideal.coe_ideal_span_singleton, ← fractional_ideal.coe_ideal_mul,
    ← fractional_ideal.coe_ideal_mul] at h_aJ,
  rw [fractional_ideal.count, dif_neg hI, sub_eq_sub_iff_add_eq_add, ← int.coe_nat_add, ← int.coe_nat_add, 
    int.coe_nat_inj', ← associates.count_mul _ _ hv, ← associates.count_mul _ _ hv, 
    associates.mk_mul_mk, associates.mk_mul_mk, fractional_ideal.coe_ideal_injective h_aJ],
  { rw [ne.def, associates.mk_eq_zero], exact h_J_ne_zero },
  { rw [ne.def, associates.mk_eq_zero, ideal.zero_eq_bot, ideal.span_singleton_eq_bot],
    exact h_a₁_ne_zero, },
  { rw [ne.def, associates.mk_eq_zero], exact h_J₁_ne_zero },
  { rw [ne.def, associates.mk_eq_zero], exact h_a_ne_zero },
end

--set_option profiler true
lemma fractional_ideal.count_mul {I I' : fractional_ideal (non_zero_divisors R) K} (hI : I ≠ 0) 
  (hI' : I' ≠ 0): 
  fractional_ideal.count K v (I*I')  = fractional_ideal.count K v (I) + 
  fractional_ideal.count K v (I') :=
begin
  have hv : irreducible (associates.mk v.val.as_ideal),
  { apply associates.irreducible_of_maximal },
  --have hII' : I*I' ≠ 0 := mul_ne_zero hI hI',
  obtain ⟨a, J, ha, haJ⟩ := fractional_ideal.exists_eq_span_singleton_mul I,
  have ha_ne_zero : associates.mk (ideal.span {a} : ideal R) ≠ 0,
  { rw [ne.def, associates.mk_eq_zero, ideal.zero_eq_bot, ideal.span_singleton_eq_bot], exact ha },
  have hJ_ne_zero : associates.mk J ≠ 0,
  { rw [ne.def, associates.mk_eq_zero], exact fractional_ideal.ideal_factor_ne_zero hI haJ },
  obtain ⟨a', J', ha', haJ'⟩ := fractional_ideal.exists_eq_span_singleton_mul I',
  have ha'_ne_zero : associates.mk (ideal.span {a'} : ideal R) ≠ 0,
  { rw [ne.def, associates.mk_eq_zero, ideal.zero_eq_bot, ideal.span_singleton_eq_bot], exact ha' },
  have hJ'_ne_zero : associates.mk J' ≠ 0,
  { rw [ne.def, associates.mk_eq_zero], exact fractional_ideal.ideal_factor_ne_zero hI' haJ' },
  have h_prod : I*I' = fractional_ideal.span_singleton (non_zero_divisors R)
    ((algebra_map R K) (a*a'))⁻¹ * ↑(J*J'),
    { rw [haJ, haJ', mul_assoc, mul_comm ↑J, mul_assoc, ← mul_assoc, 
      fractional_ideal.span_singleton_mul_span_singleton, 
      fractional_ideal.coe_ideal_mul, ring_hom.map_mul, mul_inv₀, mul_comm ↑J] },
  rw [fractional_ideal.count_well_defined K v hI haJ, 
    fractional_ideal.count_well_defined K v hI' haJ',
    fractional_ideal.count_well_defined K v (mul_ne_zero hI hI') h_prod,
    ← associates.mk_mul_mk, associates.count_mul hJ_ne_zero hJ'_ne_zero hv,
    ← ideal.span_singleton_mul_span_singleton, ← associates.mk_mul_mk,
    associates.count_mul ha_ne_zero ha'_ne_zero hv],
  push_cast,
  ring,
end

lemma fractional_ideal.count_mul' (I I' : fractional_ideal (non_zero_divisors R) K) :
  fractional_ideal.count K v (I*I')  = (if I ≠ 0 ∧ I' ≠ 0 then  fractional_ideal.count K v (I) + 
  fractional_ideal.count K v (I') else 0)
   := 
begin
  split_ifs,
  { exact fractional_ideal.count_mul K v h.1 h.2 },
  { push_neg at h,
    by_cases hI : I = 0,
    { rw [hI, zero_mul, fractional_ideal.count, dif_pos (eq.refl _)], },
    { rw [(h hI), mul_zero, fractional_ideal.count, dif_pos (eq.refl _)], }}
end
--set_option profiler false

lemma fractional_ideal.count_zero : 
  fractional_ideal.count K v (0 : fractional_ideal (non_zero_divisors R) K)  = 0 :=
by rw [fractional_ideal.count, dif_pos (eq.refl _)]

lemma fractional_ideal.count_one : 
  fractional_ideal.count K v (1 : fractional_ideal (non_zero_divisors R) K)  = 0 :=
begin
  have h_one : (1 : fractional_ideal (non_zero_divisors R) K) = fractional_ideal.span_singleton
    (non_zero_divisors R) ((algebra_map R K) (1))⁻¹ * ↑(1 : ideal R),
  { rw [(algebra_map R K).map_one, ideal.one_eq_top, fractional_ideal.coe_ideal_top, mul_one,
      inv_one, fractional_ideal.span_singleton_one], },
  rw [fractional_ideal.count_well_defined K v one_ne_zero h_one, ideal.span_singleton_one,
    ideal.one_eq_top, sub_self],
end

lemma fractional_ideal.count_pow (n : ℕ) (I : fractional_ideal (non_zero_divisors R) K) : 
  fractional_ideal.count K v (I^n) = n * fractional_ideal.count K v I :=
begin
  induction n with n h,
  { rw [pow_zero, int.coe_nat_zero, zero_mul, fractional_ideal.count_one] },
  { rw pow_succ, rw fractional_ideal.count_mul',
    by_cases hI : I = 0,
    { have h_neg : ¬ (I ≠ 0 ∧ I ^ n ≠ 0),
      { rw [not_and, not_not, ne.def], intro h, exact absurd hI h, },
      rw [if_neg h_neg, hI, fractional_ideal.count_zero, mul_zero], },
    { rw [if_pos (and.intro hI (pow_ne_zero n hI)), h, nat.succ_eq_add_one], ring, }},
end

lemma fractional_ideal.count_self : 
  fractional_ideal.count K v (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K)  = 1 :=
begin
  have hv : (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K) ≠ 0,
  { rw fractional_ideal.coe_ideal_ne_zero_iff,
    exact v.property  },
  have h_self : (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K) = 
    fractional_ideal.span_singleton (non_zero_divisors R) ((algebra_map R K) 1)⁻¹ * 
    ↑(v.val.as_ideal),
  { rw [(algebra_map R K).map_one, inv_one, fractional_ideal.span_singleton_one, one_mul], },
    rw fractional_ideal.count_well_defined K v hv h_self,

  have hv_irred : irreducible (associates.mk v.val.as_ideal),
    { apply associates.irreducible_of_maximal v },
  rw associates.count_self hv_irred,
  rw [ideal.span_singleton_one, ← ideal.one_eq_top, associates.mk_one, 
      associates.factors_one, associates.count_zero hv_irred, int.coe_nat_zero, sub_zero, 
      int.coe_nat_one],
end

lemma fractional_ideal.count_pow' (n : ℕ) : 
  fractional_ideal.count K v
  ((v.val.as_ideal : fractional_ideal (non_zero_divisors R) K)^n) = n := 
by rw [fractional_ideal.count_pow, fractional_ideal.count_self, mul_one]

lemma fractional_ideal.count_inv (n : ℤ) (I : fractional_ideal (non_zero_divisors R) K) : 
  fractional_ideal.count K v (I^-n) = - fractional_ideal.count K v (I^n) := 
begin
  by_cases hI : I = 0,
  {by_cases hn : n = 0,
    { rw [hn, neg_zero, zpow_zero, fractional_ideal.count_one, neg_zero], },
    { rw [hI, zero_zpow n hn, zero_zpow (-n) (neg_ne_zero.mpr hn), fractional_ideal.count_zero,
        neg_zero], }},
  { rw [eq_neg_iff_add_eq_zero,
    ←  fractional_ideal.count_mul K v (zpow_ne_zero _ hI) (zpow_ne_zero _ hI),
    ← zpow_add₀ hI, neg_add_self, zpow_zero],
    exact fractional_ideal.count_one K v, }
end

lemma fractional_ideal.count_zpow (n : ℤ) (I : fractional_ideal (non_zero_divisors R) K) : 
  fractional_ideal.count K v (I^n) = n * fractional_ideal.count K v I := 
begin
  cases n,
  { exact fractional_ideal.count_pow K v n I, },
  { rw [int.neg_succ_of_nat_coe, fractional_ideal.count_inv, zpow_coe_nat, 
      fractional_ideal.count_pow], ring, }
end

lemma fractional_ideal.count_zpow' (n : ℤ) : 
  fractional_ideal.count K v
  ((v.val.as_ideal : fractional_ideal (non_zero_divisors R) K)^n) = n := 
by rw [fractional_ideal.count_zpow, fractional_ideal.count_self, mul_one]

lemma fractional_ideal.count_maximal_coprime (w : maximal_spectrum R) (hw : w ≠ v) :
  fractional_ideal.count K v (w.val.val : fractional_ideal (non_zero_divisors R) K) = 0 := 
begin
  have hw_fact : (w.val.val : fractional_ideal (non_zero_divisors R) K) =
   fractional_ideal.span_singleton
    (non_zero_divisors R) ((algebra_map R K) (1))⁻¹ * ↑(w.val.val),
  { rw [(algebra_map R K).map_one, inv_one, fractional_ideal.span_singleton_one, one_mul], },
  have hw_ne_zero : (w.val.val : fractional_ideal (non_zero_divisors R) K) ≠ 0,
  { rw fractional_ideal.coe_ideal_ne_zero_iff,
    exact w.property  },
  have hv : irreducible (associates.mk v.val.val) := by apply associates.irreducible_of_maximal v,
  have hw' : irreducible (associates.mk w.val.val) := by apply associates.irreducible_of_maximal w,
  rw [fractional_ideal.count_well_defined K v hw_ne_zero hw_fact, ideal.span_singleton_one,
    ← ideal.one_eq_top, associates.mk_one, associates.factors_one, associates.count_zero hv,
    int.coe_nat_zero, sub_zero, int.coe_nat_eq_zero, ← pow_one (associates.mk w.val.val),
    associates.factors_prime_pow hw', associates.count_some hv, multiset.repeat_one, 
    multiset.count_eq_zero, multiset.mem_singleton],
  simp only [subtype.val_eq_coe],
  rw [associates.mk_eq_mk_iff_associated, associated_iff_eq, ← ne.def, 
    injective.ne_iff subtype.coe_injective, injective.ne_iff subtype.coe_injective],
  exact ne.symm hw,
end
lemma fractional_ideal.count_finprod_coprime (exps : maximal_spectrum R → ℤ) :
  fractional_ideal.count K v (∏ᶠ (i : maximal_spectrum R) (H : i ∈ mul_support 
  (λ (i : maximal_spectrum R), (i.val.as_ideal : fractional_ideal (non_zero_divisors R) K) ^ exps i)
  \ {v}), ↑(i.val.as_ideal) ^ exps i) = 0 :=
begin
  apply finprod_mem_induction (λ I, fractional_ideal.count K v I = 0),
  { exact fractional_ideal.count_one K v },
  { intros I I' hI hI',
    by_cases h : I ≠ 0 ∧ I' ≠ 0,
    { rw [fractional_ideal.count_mul' K v, if_pos h, hI, hI', add_zero] },
    { rw [fractional_ideal.count_mul' K v, if_neg h], }},
  { intros w hw,
    rw [mem_diff, mem_singleton_iff] at hw,
    rw [fractional_ideal.count_zpow, fractional_ideal.count_maximal_coprime K v w hw.2, mul_zero] }
end

lemma fractional_ideal.count_finprod (exps : maximal_spectrum R → ℤ)
(h_exps : ∀ᶠ (v : maximal_spectrum R) in filter.cofinite, exps v = 0 ) :
fractional_ideal.count K v (∏ᶠ (v : maximal_spectrum R), 
  (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K)^(exps v)) = exps v :=
begin
  have h_supp : (mul_support (λ (i : maximal_spectrum R), ↑(i.val.as_ideal) ^ exps i)).finite,
  { have h_subset : {v : maximal_spectrum R | 
      (v.val.as_ideal : fractional_ideal (non_zero_divisors R) K) ^ exps v ≠ 1} ⊆ 
      {v : maximal_spectrum R | exps v ≠ 0},
    { intros v hv,
      by_contradiction h,
      rw [nmem_set_of_eq, not_not] at h,
      rw [mem_set_of_eq, h, zpow_zero] at hv,
      exact hv (eq.refl 1),},
    exact finite.subset h_exps h_subset, },
  rw [← finprod_mem_dvd' v h_supp, fractional_ideal.count_mul, fractional_ideal.count_zpow',
    fractional_ideal.count_finprod_coprime, add_zero],
  { apply zpow_ne_zero, 
    exact fractional_ideal.coe_ideal_ne_zero_iff.mpr v.property,},
  { have hfin : (mul_support (λ (i : maximal_spectrum R), ↑(i.val.as_ideal) ^ exps i) \ {v}).finite,
    { exact finite.subset h_supp (diff_subset _ _)},
    rw [finprod_mem_eq_finite_to_finset_prod _ hfin, finset.prod_ne_zero_iff],
    intros w hw,
    apply zpow_ne_zero, 
    exact fractional_ideal.coe_ideal_ne_zero_iff.mpr w.property, }
end

variables (R K)
def pi.unif : Π v : maximal_spectrum R, K_v K v := λ v : maximal_spectrum R, (coe : K → (K_v K v))
  (classical.some (adic_valuation.exists_uniformizer K v))

lemma pi.unif.ne_zero :
  ∀ v : maximal_spectrum R, pi.unif R K v ≠ 0 :=
begin
  intro v,
  rw [pi.unif, ← uniform_space.completion.coe_zero,
    injective.ne_iff (@uniform_space.completion.coe_inj K (us' v) (ss v))],
  exact adic_valuation.uniformizer_ne_zero K v,
end

variables {R K}
lemma idele.mk'.val {exps : Π v : maximal_spectrum R, ℤ}
  (h_exps : ∀ᶠ (v : maximal_spectrum R) in filter.cofinite, exps v = 0) :
   ∀ᶠ (v : maximal_spectrum R) in filter.cofinite, pi.unif R K v ^ exps v ∈ R_v K v :=
begin
  rw filter.eventually_cofinite at h_exps ⊢,
  simp_rw K_v.is_integer,
  have h_subset : {x : maximal_spectrum R | ¬ valued.v (pi.unif R K x ^ exps x) ≤ 1} ⊆ 
    {x : maximal_spectrum R | ¬exps x = 0},
  { intros v hv,
    rw mem_set_of_eq at hv ⊢,
    intro h_zero,
    rw [h_zero, zpow_zero, valuation.map_one, not_le, lt_self_iff_false] at hv,
    exact hv, },
    exact finite.subset h_exps h_subset,
end

lemma idele.mk'.inv {exps : Π v : maximal_spectrum R, ℤ}
  (h_exps : ∀ᶠ (v : maximal_spectrum R) in filter.cofinite, exps v = 0) :
   ∀ᶠ (v : maximal_spectrum R) in filter.cofinite, pi.unif R K v ^-exps v ∈ R_v K v :=
begin
  rw filter.eventually_cofinite at h_exps ⊢,
  simp_rw K_v.is_integer,
  have h_subset : {x : maximal_spectrum R | ¬ valued.v (pi.unif R K x ^ -exps x) ≤ 1} ⊆ 
    {x : maximal_spectrum R | ¬exps x = 0},
  { intros v hv,
    rw mem_set_of_eq at hv ⊢,
    intro h_zero,
    rw [h_zero, neg_zero, zpow_zero, valuation.map_one, not_le, lt_self_iff_false] at hv,
    exact hv, },
    exact finite.subset h_exps h_subset,
end

lemma idele.mk'.mul_inv {exps : Π v : maximal_spectrum R, ℤ}
  (h_exps : ∀ᶠ (v : maximal_spectrum R) in filter.cofinite, exps v = 0) :
  (⟨λ (v : maximal_spectrum R), pi.unif R K v ^ exps v, 
    idele.mk'.val h_exps⟩ : finite_adele_ring' R K) *
    ⟨λ (v : maximal_spectrum R), pi.unif R K v ^ -exps v, idele.mk'.inv h_exps⟩ = 1 :=
begin
  ext v,
  unfold_projs,
  simp only [mul'],
  rw [subtype.coe_mk, subtype.coe_mk, pi.mul_apply, zpow_eq_pow, zpow_eq_pow,
    ← zpow_add₀ (pi.unif.ne_zero R K v)],
  have : (exps v).neg = - exps v := rfl,
  rw [this, add_right_neg, zpow_zero],
  refl,
end

lemma idele.mk'.inv_mul {exps : Π v : maximal_spectrum R, ℤ}
  (h_exps : ∀ᶠ (v : maximal_spectrum R) in filter.cofinite, exps v = 0) :
  (⟨λ (v : maximal_spectrum R), pi.unif R K v ^-exps v, 
    idele.mk'.inv h_exps⟩ : finite_adele_ring' R K) *
    ⟨λ (v : maximal_spectrum R), pi.unif R K v ^ exps v, idele.mk'.val h_exps⟩ = 1 :=
begin
  rw mul_comm, exact idele.mk'.mul_inv h_exps,
end

variables (R K)
def idele.mk' {exps : Π v : maximal_spectrum R, ℤ}
  (h_exps : ∀ᶠ (v : maximal_spectrum R) in filter.cofinite, exps v = 0) : finite_idele_group' R K :=
⟨⟨λ v : maximal_spectrum R, (pi.unif R K v)^exps v, idele.mk'.val h_exps⟩,
  ⟨λ v : maximal_spectrum R, (pi.unif R K v)^-exps v, idele.mk'.inv h_exps⟩,
  idele.mk'.mul_inv h_exps, idele.mk'.inv_mul h_exps⟩

variables {R K}
lemma idele.mk'.valuation_ne_zero {exps : Π v : maximal_spectrum R, ℤ}
  (h_exps : ∀ᶠ (v : maximal_spectrum R) in filter.cofinite, exps v = 0) :
  valued.v ((idele.mk' R K h_exps).val.val v) ≠ 0 :=
begin
  rw [ne.def, valuation.zero_iff],
  simp only [idele.mk'],
  intro h,
  exact pi.unif.ne_zero R K v (zpow_eq_zero h),
end

lemma fractional_ideal.finite_factors {I : fractional_ideal (non_zero_divisors R) K} (hI : I ≠ 0)
  {a : R} {J : ideal R} 
  (haJ : I = fractional_ideal.span_singleton (non_zero_divisors R) ((algebra_map R K) a)⁻¹ * ↑J) :
  ∀ᶠ v : maximal_spectrum R in filter.cofinite,
  (((associates.mk v.val.as_ideal).count (associates.mk J).factors : ℤ) - 
    ((associates.mk v.val.as_ideal).count (associates.mk (ideal.span {a})).factors) = 0) :=
begin
  have ha_ne_zero : ideal.span{a} ≠ 0 := fractional_ideal.constant_factor_ne_zero hI haJ,
  have hJ_ne_zero : J ≠ 0 := fractional_ideal.ideal_factor_ne_zero hI haJ,
  rw filter.eventually_cofinite,
  have h_subset : {v : maximal_spectrum R | ¬((associates.mk v.val.as_ideal).count 
    (associates.mk J).factors : ℤ) - 
    ↑((associates.mk v.val.as_ideal).count (associates.mk (ideal.span {a})).factors) = 0} ⊆ 
    {v : maximal_spectrum R | v.val.as_ideal ∣ J} ∪ 
    {v : maximal_spectrum R | v.val.as_ideal ∣ (ideal.span {a})},
  { intros v hv,
    have hv_irred : irreducible v.val.as_ideal := ideal.irreducible_of_maximal v,
    by_contradiction h_nmem,
    rw [mem_union_eq, mem_set_of_eq, mem_set_of_eq] at h_nmem,
    push_neg at h_nmem,  
    rw [← associates.count_ne_zero_iff_dvd ha_ne_zero hv_irred, not_not, 
    ← associates.count_ne_zero_iff_dvd hJ_ne_zero hv_irred, not_not] 
      at h_nmem,
    rw [mem_set_of_eq, h_nmem.1, h_nmem.2, sub_self] at hv,
    exact hv (eq.refl 0),
   },
  exact finite.subset (finite.union 
    (ideal.finite_factors (fractional_ideal.ideal_factor_ne_zero hI haJ)) 
    (ideal.finite_factors (fractional_ideal.constant_factor_ne_zero hI haJ)))
    h_subset,
end

lemma map_to_fractional_ideals.surjective : surjective (map_to_fractional_ideals R K) :=
begin
  rintro ⟨I, I_inv, hval_inv, hinv_val⟩,
  obtain ⟨a, J, ha, haJ⟩ := fractional_ideal.exists_eq_span_singleton_mul I,
  have hI_ne_zero : I ≠ 0 := left_ne_zero_of_mul_eq_one hval_inv,
  have hI := fractional_ideal.factorization I hI_ne_zero haJ,
  have h_exps : ∀ᶠ v : maximal_spectrum R in filter.cofinite,
  ((associates.mk v.val.as_ideal).count (associates.mk J).factors : ℤ) - 
    ((associates.mk v.val.as_ideal).count (associates.mk (ideal.span {a})).factors) = 0 :=
   fractional_ideal.finite_factors hI_ne_zero haJ,
  use idele.mk' R K h_exps,
  rw map_to_fractional_ideals,
  simp only [map_to_fractional_ideals.def, monoid_hom.coe_mk],
  have H : map_to_fractional_ideals.val R K (idele.mk' R K h_exps) = I,
  { simp only [map_to_fractional_ideals.val, finite_idele.to_add_valuations, ← hI],
    apply finprod_congr,
    intro v,
    apply congr_arg,
    have hv : valued.v ((idele.mk' R K h_exps).val.val v) ≠ 0 := 
    idele.mk'.valuation_ne_zero v h_exps,
    rw with_zero.to_integer,
    set x := classical.some (with_zero.to_integer._proof_1 hv) with hx_def,
    have hx := classical.some_spec (with_zero.to_integer._proof_1 hv),
    rw ← hx_def at hx ⊢,
    simp only [idele.mk', pi.unif] at hx,
    rw [valuation.map_zpow, valued_K_v.def, valued.extension_extends,
      v_valued_K.def, classical.some_spec (adic_valuation.exists_uniformizer K v), 
        ← with_zero.coe_zpow, with_zero.coe_inj] at hx,
    rw [hx, ← of_add_zsmul, to_add_of_add, algebra.id.smul_eq_mul, mul_neg_eq_neg_mul_symm, 
          mul_one, neg_neg], },
  exact ⟨H, map_to_fractional_ideals.inv_eq_inv _ ⟨I, I_inv, hval_inv, hinv_val⟩ H⟩,
end

lemma map_to_fractional_ideals.mem_kernel_iff (x : finite_idele_group' R K) : 
  map_to_fractional_ideals R K x = 1 ↔ 
  ∀ v : maximal_spectrum R, finite_idele.to_add_valuations R K x v = 0 :=
begin
  rw [map_to_fractional_ideals, monoid_hom.coe_mk, map_to_fractional_ideals.def],
  simp_rw map_to_fractional_ideals.val,
  rw [units.ext_iff, units.coe_mk, units.coe_one],
  refine ⟨λ h_ker, _, λ h_val, _⟩,
  { intro v,
    rw [← fractional_ideal.count_finprod K v (finite_idele.to_add_valuations R K x),
      ← fractional_ideal.count_one K v, h_ker],
    exact finite_add_support R K x, },
  { rw ← @finprod_one _ (maximal_spectrum R) _,
    apply finprod_congr,
    intro v,
    rw [h_val v, zpow_zero _] }
end

variables (R K)
instance ufi_ts : topological_space (units (fractional_ideal (non_zero_divisors R) K)) := ⊥

instance ufi_tg : topological_group (units (fractional_ideal (non_zero_divisors R) K)) := 
{ continuous_mul := continuous_of_discrete_topology,
  continuous_inv := continuous_of_discrete_topology, }


@[to_additive]
lemma continuous_iff_continuous_at_one {α : Type*} {β : Type*} [topological_space α] 
  [topological_space β] [group α] [group β] [topological_group α] [topological_group β] {
  f : α →* β} : continuous f ↔ continuous_at f 1 :=
begin
  rw continuous_iff_continuous_at,
  refine ⟨λ hf, hf 1, λ hf, _⟩,
  intros x  U hUx,
  rw [filter.mem_map, ← map_mul_left_nhds_one, filter.mem_map],
  rw [← map_mul_left_nhds_one, filter.mem_map, ← monoid_hom.map_one f] at hUx,
  convert continuous_at.preimage_mem_nhds hf hUx,
  ext y,
  simp only [mem_preimage, monoid_hom.map_mul],
end

@[to_additive continuous_iff_open_add_kernel]
lemma continuous_iff_open_kernel {α : Type*} {β : Type*} [topological_space α] [topological_space β] 
  [discrete_topology β] [group α] [group β] [topological_group α] [topological_group β]
  {f : α →* β} : continuous f ↔ is_open (f⁻¹' {1}) := 
begin
  refine ⟨λ hf, _, λ hf, _⟩,
  { apply continuous.is_open_preimage hf _ (singletons_open_iff_discrete.mpr (infer_instance) 1) },
  { rw continuous_iff_continuous_at_one,
    intros U hU,
    rw [monoid_hom.map_one, discrete_topology_iff_nhds.mp, filter.mem_pure] at hU,
    rw [filter.mem_map, mem_nhds_iff],
    exact ⟨f ⁻¹' {1}, λ x hx, by apply (singleton_subset_iff.mpr hU) hx, hf, 
      by rw [mem_preimage, mem_singleton_iff, monoid_hom.map_one]⟩,
    { apply_instance }}
end

lemma finite_idele.to_add_valuations.comp_eq_zero_iff (x : finite_idele_group' R K) : 
  finite_idele.to_add_valuations R K x v = 0 ↔ valued.v ( x.val.val v) = 1 :=
begin
  set y := classical.some (with_zero.to_integer._proof_1 
    (finite_idele.to_add_valuations._proof_1 R K x v)) with hy,
  have hy_spec := classical.some_spec (with_zero.to_integer._proof_1 
    (finite_idele.to_add_valuations._proof_1 R K x v)),
  rw ← hy at hy_spec,
  rw [finite_idele.to_add_valuations, neg_eq_zero ,with_zero.to_integer, ← to_add_one, ← hy,
    ← hy_spec, ← with_zero.coe_one, with_zero.coe_inj],
  refine ⟨λ h_eq, by rw [← of_add_to_add y, ← of_add_to_add 1, h_eq], λ h_eq, by rw h_eq⟩,
end

lemma finite_idele.valuation_eq_one_iff (x : finite_idele_group' R K) : 
  valued.v (x.val.val v) = 1 ↔ x.val.val v ∈ R_v K v ∧ x⁻¹.val.val v ∈ R_v K v :=
begin
  rw [K_v.is_integer, K_v.is_integer],
  refine ⟨λ h_one, _, λ h_int, _⟩,
  { have h_mul := valuation_val_inv R K v x,
    rw [h_one, one_mul] at h_mul,
    exact ⟨ le_of_eq h_one, le_of_eq h_mul ⟩ , },
  { have : x.inv = x⁻¹.val := rfl,
    rw [← this, valuation_inv, ← inv_one, inv_le_inv₀, inv_one] at h_int,
    rw [eq_iff_le_not_lt, not_lt],
    exact h_int,
    { exact (valuation.ne_zero_iff _).mpr (v_comp.ne_zero R K v x)},
    { exact one_ne_zero }}
end

lemma map_to_fractional_ideals.continuous : continuous (map_to_fractional_ideals R K) := 
begin
  rw continuous_iff_open_kernel,
  have h_ker : (map_to_fractional_ideals R K) ⁻¹' {1} = 
    { x : units(finite_adele_ring' R K) |
       ∀ v : maximal_spectrum R, finite_idele.to_add_valuations R K x v = 0 },
  { ext x,
    exact map_to_fractional_ideals.mem_kernel_iff x, },
  rw h_ker,
  --rw is_open,
  --rw finite_idele_group'.topological_space,
  --rw units.topological_space,
  --rw topological_space.induced,
  --simp only,
  use {p : (finite_adele_ring' R K × (finite_adele_ring' R K)ᵐᵒᵖ) | 
    ∀ v : maximal_spectrum R, (p.1.val v) ∈ R_v K v ∧ 
    ((mul_opposite.unop p.2).val v) ∈ R_v K v},
  split,
  { have : prod.topological_space.is_open {p : finite_adele_ring' R K × (finite_adele_ring' R K)ᵐᵒᵖ 
  | ∀ (v : maximal_spectrum R), p.fst.val v ∈ R_v K v ∧ (mul_opposite.unop p.snd).val v ∈ R_v K v}
    ↔ is_open {p : finite_adele_ring' R K × (finite_adele_ring' R K)ᵐᵒᵖ 
  | ∀ (v : maximal_spectrum R), p.fst.val v ∈ R_v K v ∧ (mul_opposite.unop p.snd).val v ∈ R_v K v}
    := by refl,
    rw this, clear this,
    rw [is_open_prod_iff],
    intros x y hxy,
    use {x : finite_adele_ring' R K | ∀ (v : maximal_spectrum R), x.val v ∈ R_v K v},
    use {x : (finite_adele_ring' R K )ᵐᵒᵖ | ∀ (v : maximal_spectrum R), 
      (mul_opposite.unop x).val v ∈ R_v K v},
    refine ⟨_, by sorry, by sorry, by sorry, _⟩,
    { 
      sorry},
    { intros p hp v,
      exact ⟨ hp.1 v, hp.2 v⟩, }},
  { rw preimage_set_of_eq,
    ext x,
    rw [mem_set_of_eq, embed_product, monoid_hom.coe_mk, mul_opposite.unop_op],
    simp_rw [finite_idele.to_add_valuations.comp_eq_zero_iff, finite_idele.valuation_eq_one_iff],
    refl, },
end



