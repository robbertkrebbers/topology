Require Import FormTopC.FormTop 
  FormTopC.Cont
  Algebra.FrameC FormTopC.Product FormTopC.InfoBase 
  Algebra.SetsC.

Set Universe Polymorphism.
Set Asymmetric Patterns.

Delimit Scope loc_scope with loc.
Local Open Scope loc.

Module Bundled.

(* Inductively-generated formal topology *)
Record IGT : Type :=
  { S : Type
  ; le : S -> Subset S
  ; PO :> PreO.t le
  ; Ix : S -> Type
  ; C : forall s, Ix s -> Subset S
  ; localized : FormTop.localized le C
  }.

Local Instance IGT_PreO `(X : IGT) : PreO.t (le X) := PO X.

Generalizable All Variables.

Definition Cov (X : IGT) := FormTop.GCov (le X) (C X).

Local Instance local `(X : IGT) : FormTop.localized (le X) (C X)
  := localized X.

Local Instance IGTFT `(X : IGT) : FormTop.t (le X) (Cov X) :=
  FormTop.GCov_formtop _ _.

Definition InfoBase {A : Type} {ops : MeetLat.Ops A}
  (ML : MeetLat.t A ops) : IGT :=
  {| S := A 
  ; PO := PO.PreO
  ; localized := @InfoBase.loc _ _ _ MeetLat.PO
  |}.

Definition One : IGT := InfoBase MeetLat.one.

Definition times `(LA : IGT) `(LB : IGT) : IGT :=
  let PO1 := PO LA in let PO2 := PO LB in
  {| PO := Product.PO (S LA) (S LB)
  ; localized := Product.loc _ _ _ _ _ _ (localized LA) (localized LB)
  |}.

Infix "*" := times : loc_scope.

Record cmap `{LA : IGT} `{LB : IGT} : Type :=
  { mp : Cont.map (S LA) (S LB)
  ; mp_ok : Cont.t (le LA) (le LB) (Cov LA) (Cov LB) mp
  }.

Arguments cmap LA LB : clear implicits.

Infix "~~>" := cmap (at level 75) : loc_scope.

Definition id `{LA : IGT} : LA ~~> LA := 
  {| mp := Cont.id
  ; mp_ok := Cont.t_id |}.

Definition comp `{LA : IGT} 
  `{LB : IGT} `{LD : IGT} (f : LB ~~> LD) (g : LA ~~> LB) : LA ~~> LD :=
  {| mp := compose (mp f) (mp g) 
  ; mp_ok := Cont.t_compose (mp g) (mp f) (mp_ok g) (mp_ok f)
  |}.

Infix "∘" := comp (at level 40, left associativity) : loc_scope.

Definition eq_map {A B : IGT} (f g : A ~~> B)
  : Prop := forall y : S B, inhabited (FormTop.eqA (Cov A) (mp f y) (mp g y)).

Definition point_mp (A : IGT) (f : Subset (S A))
  (fpt : Cont.pt (le A) (Cov A) f)
  : Cont.t (le One) (le A) (Cov One) (Cov A) (fun t _ => f t).
Proof.
simpl.
replace ((fun _ _ : True => True) : True -> True -> Type) with (@MeetLat.le True One.one_ops)
by reflexivity.
replace (Cov One : True -> Subset True -> Type) 
  with (One.Cov' : True -> Subset True -> Type) by reflexivity.
apply (One.pt_to_map (leS := le A) (Cov A) f).
assumption.
(** Is this a Coq bug? 
Qed. *)
Admitted.

Definition point (A : IGT) (f : S A -> Prop) (fpt : Cont.pt (le A) (Cov A) f)
  : One ~~> A :=
  {| mp := fun t _ => f t
   ; mp_ok := point_mp A f fpt
  |}.

Definition One_intro_mp {A : IGT} : Cont.map (S A) (S One)
  := One.One_intro.

Require Import FunctionalExtensionality.

Definition One_intro_mp_ok {A : IGT} :
  Cont.t (le A) (le One) (Cov A) (Cov One)
  One_intro_mp.
Proof.
simpl. replace (Cov One : True -> Subset True -> Type) 
  with (One.Cov' : True -> Subset True -> Type) by reflexivity.
unfold One_intro_mp.
apply One.One_intro_cont.
(* Same Coq bug? or universe issues?
Qed. *)
Admitted.

Definition One_intro `{A : IGT} : A ~~> One :=
  {| mp := One_intro_mp
   ; mp_ok := One_intro_mp_ok
  |}.

Definition const {Γ A : IGT} (pt : One ~~> A) : Γ ~~> A
  := pt ∘ One_intro.

Definition proj1_mp {A B : IGT} : Cont.map (S (A * B)) (S A)
   := ProductMaps.proj_L (leS := le A).

Lemma proj1_mp_ok {A B : IGT} :
  Cont.t (le (A * B)) (le A) (Cov (A * B)) (Cov A)
  proj1_mp.
Proof.
simpl.
pose proof (PO A).
apply ProductMaps.t_proj_L; try apply localized.
apply PO.
Qed.

Definition proj1 {A B : IGT} : A * B ~~> A :=
  {| mp := proj1_mp
  ; mp_ok := proj1_mp_ok
  |}.

Definition proj2_mp {A B : IGT} : Cont.map (S (A * B)) (S B)
  := ProductMaps.proj_R (leT := le B).

Lemma proj2_mp_ok {A B : IGT} :
  Cont.t (le (A * B)) (le B) (Cov (A * B)) (Cov B)
  proj2_mp.
Proof.
simpl.
pose proof (PO A).
apply ProductMaps.t_proj_R; try apply localized.
apply PO.
Qed.

Definition proj2 {A B : IGT} : A * B ~~> B :=
  {| mp := proj2_mp
  ; mp_ok := proj2_mp_ok
  |}.

Definition diagonal_mp {A : IGT} : Cont.map (S A) (S (A * A))
  := ProductMaps.diagonal (leS := le A).

Definition diagonal_mp_ok {A : IGT} :
  Cont.t (le A) (le (A * A)) (Cov A) (Cov (A * A)) diagonal_mp.
Proof.
simpl. pose proof (PO A). apply ProductMaps.t_diagonal.
apply localized.
Qed.

Definition diagonal {A : IGT} : A ~~> A * A :=
  {| mp := diagonal_mp
  ; mp_ok := diagonal_mp_ok
  |}.

Definition parallel_mp {A B X Y : IGT} 
  (f : A ~~> X) (g : B ~~> Y) : Cont.map (S (A * B)) (S (X * Y))
  := ProductMaps.parallel (mp f) (mp g).

Definition parallel_mp_ok {A B X Y : IGT}
  (f : A ~~> X) (g : B ~~> Y) :
  Cont.t (le (A * B)) (le (X * Y)) (Cov (A * B)) (Cov (X * Y))
  (parallel_mp f g).
Proof.
simpl. apply ProductMaps.t_parallel; try typeclasses eauto.
apply (mp_ok f). apply (mp_ok g).
Qed.

Definition parallel {A B X Y : IGT} (f : A ~~> X) (g : B ~~> Y)
  : A * B ~~> X * Y :=
  {| mp := parallel_mp f g
   ; mp_ok := parallel_mp_ok f g
  |}.

Definition discrete (A : Type) : IGT :=
  {| S := A 
  ; PO := PreO.discrete A
  ; localized := @InfoBase.loc _ _ _ (PO.discrete A)
  |}.

(** Spaces of open sets (using Scott topology *)
Definition Open (A : IGT) : IGT :=
  let LE := @Scott.le_Open (S A) (le A) (Ix A) (C A) in 
  let PreO : PreO.t (le A) := IGT_PreO A in
  let PO := 
   @PO.PreO (Subset (S A)) LE _ (Scott.PO_le_eq (POT := PreO)
  (locT := localized A)) in
  {| S := Subset (S A)
   ; le := LE
   ; PO := PO
   ; Ix := InfoBase.Ix
   ; C := InfoBase.C (leS := LE) (eqS := PO.eq_PreO LE)
   ; localized := InfoBase.loc (PO := PO.fromPreO LE)
  |}.

Definition Σ : IGT := InfoBase Sierpinski.SML.

Definition Σand_mp : Cont.map (S (Σ * Σ)) (S Σ) := Sierpinski.sand.

(** I need to prove that a the information-base product of meet lattices
    is the same as the product of the information bases

    This will be phrased as a homeomorphism!
*)
(** Sierpinski.sand_cont *)
Definition Σand_mp_ok : Cont.t (le (Σ * Σ)) (le Σ)
  (Cov (Σ * Σ)) (Cov Σ) Σand_mp.
Proof.
simpl. unfold Cov. simpl. 
Admitted.

Definition Σand : Σ * Σ ~~> Σ :=
  {| mp := Σand_mp
   ; mp_ok := Σand_mp_ok
  |}.

Definition Σor_mp : Cont.map (S (Σ * Σ)) (S Σ) := Sierpinski.sor.

(** Sierpinski.sor_cont *)
Definition Σor_mp_ok : Cont.t (le (Σ * Σ)) (le Σ)
  (Cov (Σ * Σ)) (Cov Σ) Σor_mp.
Proof.
simpl. unfold Cov. simpl. 
Admitted.

Definition Σor : Σ * Σ ~~> Σ :=
  {| mp := Σor_mp
   ; mp_ok := Σor_mp_ok
  |}.

Definition open_abstract_mp {Γ A : IGT}
  (f : Cont.map (S (Γ * A)) (S Σ))
     : Cont.map (S Γ) (S (Open A))
  := Scott.absF (leT := le A) (IxT := Ix A) (CT := C A) f.

Definition open_abstract_mp_ok {Γ A : IGT}
  (f : Cont.map (S (Γ * A)) (S Σ))
  : Cont.t (le (Γ * A)) (le Σ) (Cov (Γ * A)) (Cov Σ) f
  -> Cont.t (le Γ) (le (Open A)) (Cov Γ) (Cov (Open A)) 
    (open_abstract_mp f).
Proof.
intros H.
apply Scott.absF_cont. apply H.
Qed.

Definition open_abstract {Γ A : IGT} (f : Γ * A ~~> Σ) : Γ ~~> Open A
  := 
  {| mp := open_abstract_mp (mp f)
   ; mp_ok := open_abstract_mp_ok (mp f) (mp_ok f)
  |}.

Class Hausdorff {A : IGT} : Type :=
  { apart : A * A ~~> Σ }.

Arguments Hausdorff A : clear implicits.

(** Could have used Sierpinski? *)
Class Discrete {A : IGT} : Type :=
  { bequal : A * A ~~> discrete bool }.

Require Import Spec.Category.
Import Category.

Instance IGT_Cat : CCat IGT :=
  {| arrow := cmap
  ;  prod := times
  ; eq := fun _ _ => eq_map
  |}.

Instance IGT_CMC : CMC IGT :=
  {| id := fun _ => Bundled.id
   ; compose := fun _ _ _ => comp
   
   ; unit := One
   ; tt := fun _ => One_intro

  ; fst := fun _ _ => proj1
  ; snd := fun _ _ => proj2

  ; diagonal := fun _ => Bundled.diagonal
  ; parallel := fun _ _ _ _ => Bundled.parallel
  |}.
Proof.
Admitted.


End Bundled.