Require Import Qnn.

Local Open Scope Qnn.

Require Import FunctionalExtensionality.

(** Nonnegative lower reals *)
(* These guys are interesting because we can have proofy
   bits in them. For example, we can create a real number
   which is 0 if P = NP and 1 if P /= NP. *)
Record LPReal :=
  { lbound :> Qnn -> Prop
  ; dclosed : forall q, lbound q -> forall q', q' <= q -> lbound q'
  ; uopen   : forall q, lbound q -> exists q', q < q' /\ lbound q'
  }.

Definition LPRle (r s : LPReal) : Prop :=
  forall q, r q -> s q.

Definition LPRge (r s : LPReal) : Prop := LPRle s r.

Definition LPRlt (r s : LPReal) : Prop :=
  exists q, ~ r q /\ s q.

Definition LPRgt (r s : LPReal) : Prop := LPRlt s r.

Definition LPRle_refl (r : LPReal) : LPRle r r :=
  fun _ p => p.

Definition LPRle_trans {r s t : LPReal} 
  (rs : LPRle r s) (st : LPRle s t) : LPRle r t :=
  fun q prf => (st q (rs q prf)).

Definition LPReq (r s : LPReal) : Prop :=
  LPRle r s /\ LPRle s r.

Lemma LPReq_refl (x : LPReal) : LPReq x x.
Proof. split; apply LPRle_refl. Qed.

Lemma LPReq_trans (x y z : LPReal) 
  : LPReq x y -> LPReq y z -> LPReq x z.
Proof. intros. destruct H; destruct H0; split;
  eapply LPRle_trans; eassumption.
Qed.

Lemma LPReq_compat_backwards (x y : LPReal) : x = y -> LPReq x y.
Proof. intros H; induction H; apply LPReq_refl. Qed.

Definition LPRQnn (q : Qnn) : LPReal.
Proof.
refine (
  {| lbound := fun q' => (q' < q)%Qnn |}
).
- intros. subst. eapply Qnnle_lt_trans; eassumption.
- intros. pose proof (Qnnbetween q0 q H). destruct H0.
  exists x. assumption.
Defined.

Inductive LPRplusT {x y : LPReal} : Qnn -> Prop :=
  | LPRplusL : forall q, x q -> LPRplusT q
  | LPRplusR : forall q, y q -> LPRplusT q
  | LPRplusB : forall q q' sum , x q -> y q' -> sum <= q + q' -> LPRplusT sum.

Arguments LPRplusT : clear implicits.

Definition LPRplus (x y : LPReal) : LPReal.
Proof.
refine (
  {| lbound := LPRplusT x y |}
).
- intros.
  inversion H; subst; 
  [apply LPRplusL | apply LPRplusR | eapply LPRplusB].
  eapply dclosed; eassumption.
  eapply dclosed; eassumption.
  eassumption. eassumption. 
  eapply Qnnle_trans; eassumption.
- intros. destruct H.
  + pose proof (uopen _ _ H). destruct H0.
    exists x0. intuition. apply LPRplusL. assumption.
  + pose proof (uopen _ _ H). destruct H0.
    exists x0. intuition. apply LPRplusR. assumption.
  + pose proof (uopen _ _ H). destruct H2. 
    exists (x0 + q'). intuition. eapply Qnnle_lt_trans. eassumption.
    rewrite (SRadd_comm Qnnsrt).
    rewrite (SRadd_comm Qnnsrt x0).
    apply Qnnplus_le_lt_compat. apply Qnnle_refl. assumption. 
    eapply LPRplusB. eassumption. eassumption. apply Qnnle_refl.
Defined.

Definition LPRmult (x y : LPReal) : LPReal.
Proof.
refine (
  {| lbound := fun q => exists a b,
     lbound x a /\ lbound y b /\ (q <= a * b)%Qnn |}
).
- intros.
  destruct H as [a [b [xa [yb sum]]]].
  exists a. exists b. intuition. eapply Qnnle_trans; eassumption.
- intros. destruct H as [a [b [pa [pb prod]]]].
  pose proof (uopen _ _ pa). destruct H as [a' [pa' xa']].
  pose proof (uopen _ _ pb). destruct H as [b' [pb' yb']].
  exists (a' * b'). split. eapply Qnnle_lt_trans. eassumption.
  apply Qnnle_lt_trans with (a * b').
  apply Qnnmult_le_compat. apply Qnnle_refl. apply Qnnlt_le_weak.
  assumption. apply Qnnmult_lt_compat_r.
  eapply Qnnle_lt_trans. apply (nonneg b). assumption. assumption.
  exists a'. exists b'. intuition. apply Qnnle_refl.
Defined.


Lemma LPReq_prop : forall r s, LPReq r s ->
  forall q, lbound r q <-> lbound s q.
Proof.
intros. destruct H. split. apply H. apply H0.
Qed.

Lemma LPReq_compat_OK 
  (propext : forall (x y : Prop), (x <-> y) -> x = y)
  (proof_irrel : forall (P : Prop) (x y : P), x = y)
  : forall r s, LPReq r s -> r = s. 
Proof.
intros. pose proof H as eq. destruct H.
unfold LPRle in *.
assert (lbound r = lbound s).
apply functional_extensionality.
intros q. apply propext. apply LPReq_prop.
assumption.
destruct r, s.
simpl in *. induction H1.
pose proof (proof_irrel _ dclosed0 dclosed1).
induction H1.
pose proof (proof_irrel _ uopen0 uopen1).
induction H1.
reflexivity.
Qed.

Axiom LPReq_compat : forall r s, LPReq r s -> r = s.

Ltac LPRsrttac := 
repeat match goal with
| [ |- _ /\ _ ] => split
| [ |- forall _, _] => intros
| [ H : lbound (LPRQnn _) _ |- _ ] => simpl in H
| [ H : lbound (LPRplus _ _) _ |- _ ] => destruct H
| [ H : lbound (LPRmult _ _) _ |- _ ] => destruct H
| [ H : exists x, _ |- _ ] => destruct H
| [ H : _ /\ _ |- _ ] => destruct H
| [ H : _ < 0 |- _ ] => apply Qnnlt_not_le in H; unfold not in H;
  apply False_rect; apply H; apply nonneg
| [ |- lbound (LPRplus (LPRQnn 0) _) _ ] => apply LPRplusR
| [ |- lbound (LPRplus _ (LPRQnn 0)) _ ] => apply LPRplusL
| [ Hm : lbound ?m _, Hn : lbound ?n _ |- lbound (LPRplus ?m ?n) _ ]
   => eapply LPRplusB; [ eassumption | eassumption | ]
| [ Hm : lbound ?m ?q |- lbound (LPRplus ?m _) ?q ]
   => apply LPRplusL
| [ Hn : lbound ?n ?q |- lbound (LPRplus _ ?n) ?q ]
   => apply LPRplusR
| [ |- _ ] => assumption
end.



Theorem LPRsrt : semi_ring_theory (LPRQnn 0) (LPRQnn 1)
  LPRplus LPRmult eq.
Proof.
constructor; intros; apply LPReq_compat; unfold LPReq, LPRle;
LPRsrttac.
- replace (q' + q) with (q + q') by ring. assumption.
- replace (q' + q) with (q + q') by ring. assumption.
- apply LPRplusL. LPRsrttac. 
- apply LPRplusL. LPRsrttac.
- eapply LPRplusB; try eassumption. LPRsrttac.
- apply LPRplusL. LPRsrttac.
- eapply LPRplusB; try eassumption. LPRsrttac.
- eapply LPRplusB with (q + q0) (q'). eapply LPRplusB with q q0.
  eassumption. eassumption. apply Qnnle_refl. assumption.
  eapply Qnnle_trans. eassumption. rewrite <- (SRadd_assoc Qnnsrt). 
  apply Qnnplus_le_compat. apply Qnnle_refl. assumption.
- apply LPRplusR. LPRsrttac.
- eapply LPRplusB; try eassumption. LPRsrttac.
- eapply LPRplusR. LPRsrttac.
- eapply LPRplusB; try eassumption. LPRsrttac.
- apply LPRplusR. LPRsrttac.
- eapply LPRplusB with q (q'0 + q'). assumption. 
  eapply LPRplusB with q'0 q'; try assumption.
  apply Qnnle_refl. eapply Qnnle_trans. eassumption.
  rewrite (SRadd_assoc Qnnsrt). 
  apply Qnnplus_le_compat. assumption. apply Qnnle_refl. 
- eapply dclosed. eassumption. eapply Qnnle_trans. eassumption.
  replace x0 with (1 * x0) at 2 by ring.
  apply Qnnmult_le_compat. apply Qnnlt_le_weak. assumption.
  apply Qnnle_refl.
- simpl. pose proof (uopen _ _ H). destruct H0 as [q' [qq' nq']].
  exists (Qnndiv q q'). exists q'. split. apply Qnndiv_lt. assumption. intuition.
  unfold Qnndiv. rewrite <- (SRmul_assoc Qnnsrt).
  replace (Qnninv q' * q') with 1. replace (q * 1) with q by ring.
  apply Qnnle_refl. symmetry. rewrite (SRmul_comm Qnnsrt). 
  apply Qnnmult_inv_r. eapply Qnnle_lt_trans. apply (nonneg q).
  assumption.
- simpl. exists x0. exists x. intuition.
  replace (x0 * x) with (x * x0) by ring.
  assumption.
- simpl. exists x0. exists x. intuition.
  replace (x0 * x) with (x * x0) by ring.
  assumption.
- simpl. exists (x * x1). exists x2. split.
  exists x. exists x1. intuition. apply Qnnle_refl.
  intuition. eapply Qnnle_trans. eassumption.
  rewrite <- (SRmul_assoc Qnnsrt).
  apply Qnnmult_le_compat. apply Qnnle_refl. assumption. 
- simpl. exists x1. exists (x0 * x2). intuition.
  exists x2. exists x0. intuition. rewrite (SRmul_comm Qnnsrt).
  apply Qnnle_refl. eapply Qnnle_trans. eassumption.
  replace (x1 * (x0 * x2)) with ((x1 * x2) * x0) by ring.
  apply Qnnmult_le_compat. assumption. apply Qnnle_refl.
- apply LPRplusL. simpl. exists q0. exists x0. auto.
- apply LPRplusR. simpl. exists q0. exists x0. auto.
- eapply LPRplusB. exists q0. exists x0. intuition. apply Qnnle_refl.
  exists q'. exists x0. intuition. apply Qnnle_refl. eapply Qnnle_trans.
  eassumption. rewrite <- (SRdistr_l Qnnsrt).
  apply Qnnmult_le_compat. assumption. apply Qnnle_refl.
- exists x. exists x0. intuition. apply LPRplusL. assumption.
- exists x. exists x0. intuition. apply LPRplusR. assumption.
- exists (x0 + x). exists (Qnnmax x1 x2). intuition. eapply LPRplusB; try eassumption.
  apply Qnnle_refl. 
  pattern x1, x2, (Qnnmax x1 x2). apply Qnnmax_induction; intros; assumption.
  eapply Qnnle_trans. eassumption.
  rewrite (SRdistr_l Qnnsrt). apply Qnnplus_le_compat.
  pattern x1, x2, (Qnnmax x1 x2). apply Qnnmax_induction; intros.
  eapply Qnnle_trans. eassumption. apply Qnnmult_le_compat.
  apply Qnnle_refl. assumption. assumption.
  pattern x1, x2, (Qnnmax x1 x2). apply Qnnmax_induction; intros. assumption.
  eapply Qnnle_trans. eassumption. apply Qnnmult_le_compat.
  apply Qnnle_refl. assumption.
Qed.

Add Ring LPR_Ring : LPRsrt.

Infix "<=" := LPRle : LPR_scope.
Infix ">=" := LPRge : LPR_scope.
Infix ">"  := LPRgt : LPR_scope.
Infix "<"  := LPRlt : LPR_scope.
Infix "+"  := LPRplus : LPR_scope.
Infix "*"  := LPRmult : LPR_scope.

Notation "'0'" := (LPRQnn 0) : LPR_scope.
Notation "'1'" := (LPRQnn 1) : LPR_scope.

Delimit Scope LPR_scope with LPR.

Local Open Scope LPR.

Theorem LPRplus_le_compat {x y z t : LPReal}
  : (x <= y) -> (z <= t) -> (x + z <= y + t).
Proof. intros. unfold LPRle in *. intros.
simpl in *. destruct H1;
  [apply LPRplusL | apply LPRplusR | eapply LPRplusB ]; try intuition.
apply H. eassumption. apply H0. eassumption. assumption.
Qed.

Theorem LPRmult_le_compat {x x' y y' : LPReal}
  : x <= x' -> y <= y' -> x * y <= x' * y'.
Proof.
intros. unfold LPRle in *. intros.
simpl in *. destruct H1 as [a [b [H1 [H2 H3]]]].
do 2 eexists. split. apply H. eassumption. split.
apply H0. eassumption. assumption.
Qed.

Theorem LPRzero_min (r : LPReal) : 0 <= r.
Proof.
unfold LPRle. intros q Hq. simpl in *.
apply False_rect. eapply Qnnlt_zero_prop.
eassumption.
Qed.

Lemma LPRlt_not_le {x y : LPReal}
  : x < y -> ~ (y <= x).
Proof. intros. unfold LPRlt, LPRle, not in *.
intros. destruct H as [q [notxq yq]].
apply notxq. apply H0. assumption.
Qed.


Lemma LPRQnn_le {x y : Qnn} : LPRQnn x <= LPRQnn y <-> (x <= y)%Qnn.
Proof.
split; intros.
- unfold LPRle in H. simpl in *. destruct (Qnn_dec x y).
  destruct s. apply Qnnlt_le_weak. assumption.
  pose proof (H _ q). apply Qnnlt_not_le in H0.
  apply False_rect. apply H0. apply Qnnle_refl.
  induction e. apply Qnnle_refl.
- unfold LPRle. simpl in *. intros.
  eapply Qnnlt_le_trans. eassumption. assumption.
Qed.

Lemma LPRQnn_plus {x y : Qnn} 
  : LPRQnn x + LPRQnn y = LPRQnn (x + y)%Qnn.
Proof.
apply LPReq_compat. unfold LPReq.
split; unfold LPRle; intros; simpl in *.
- destruct H; simpl in *.
  + replace q with (0 + q)%Qnn by ring. 
    replace (x + y)%Qnn with (y + x)%Qnn by ring.
    apply Qnnplus_le_lt_compat. apply nonneg. assumption. 
  + replace q with (0 + q)%Qnn by ring. 
    apply Qnnplus_le_lt_compat. apply nonneg. assumption.
  + eapply Qnnle_lt_trans. eassumption.
    eapply Qnnplus_le_lt_compat. apply Qnnlt_le_weak. 
    assumption. assumption.
- destruct (Qnn_dec x 0%Qnn) as [[H0 | H0] | H0].
  + apply Qnnlt_zero_prop in H0. contradiction.
  + destruct (Qnn_dec y 0%Qnn) as [[H1 | H1] | H1].
    * apply Qnnlt_zero_prop in H1. contradiction.
    * pose (Qnnminus _ _ (Qnnlt_le_weak H)).
      pose ((Qnnonehalf * Qnnonehalf * q0)%Qnn) as eps.
      admit.
    * apply LPRplusL. simpl.
      eapply Qnnlt_le_trans. eassumption.
      subst. replace (x + 0)%Qnn with x by ring.
      apply Qnnle_refl.
  + apply LPRplusR. simpl. eapply Qnnlt_le_trans.
    eassumption. subst. replace (0 + y)%Qnn with y by ring.
    apply Qnnle_refl.
Qed.

Definition LPRsup {A : Type} (f : A -> LPReal)
  : LPReal.
Proof.
refine (
  {| lbound := fun q => exists (idx : A), f idx q |}
).
- intros. destruct H. exists x. apply dclosed with q. assumption. assumption.
- intros. destruct H. pose proof (uopen _ _ H).
  destruct H0 as [q' [qq' fq']]. 
  exists q'. split. assumption. exists x. assumption.
Defined.

Definition LPRinfinity : LPReal.
Proof. refine (
  {| lbound := fun q => True |}
); trivial.
intros. exists (q + 1)%Qnn. intuition.
replace q with (q + 0)%Qnn at 1 by ring.
apply Qnnplus_le_lt_compat.
apply Qnnle_refl. apply Qnnlt_alt. reflexivity. 
Defined.

Theorem LPRinfinity_max (r : LPReal) : r <= LPRinfinity.
Proof.
unfold LPRle. intros. simpl. constructor.
Qed.

Lemma LPRsup_ge {A : Type} {f : A -> LPReal} {a : A} 
  : f a <= LPRsup f.
Proof. unfold LPRle. simpl. intros. eexists. eassumption.
Qed.

Lemma LPRsup_le {A : Type} {f : A -> LPReal} {x : LPReal} 
  : (forall (a : A), (f a <= x)) -> LPRsup f <= x.
Proof. intros. unfold LPRle in *. simpl. intros. destruct H0.
subst. apply H with x0.
assumption.
Qed.

Lemma LPRsup_ge2 {A : Type} {f : A -> LPReal} {x : LPReal} 
  : (exists a, x <= f a) -> x <= LPRsup f.
Proof. intros. destruct H. eapply LPRle_trans. eassumption. apply LPRsup_ge.
Qed.

Lemma LPRsup_prop {A : Type} {f : A -> LPReal} {x : LPReal}
  : (forall (a : A), (f a <= x))
  -> (exists (a : A), x <= f a)
  -> LPRsup f = x.
Proof. intros. apply LPReq_compat. split. apply LPRsup_le.
assumption. eapply LPRsup_ge2. eassumption.
Qed.

Lemma LPRsup_monotonic_gen {A B : Type} (f : A -> LPReal) (g : B -> LPReal)
  : (forall (a : A), exists (b : B), f a <= g b) -> LPRsup f <= LPRsup g.
Proof.
intros mono. unfold LPRle in *.
intros. simpl in *. destruct H. 
destruct (mono x).
exists x0. apply H0.  assumption.
Qed.

Lemma LPRsup_monotonic {A : Type} (f g : A -> LPReal)
  : (forall (a : A), f a <= g a) -> LPRsup f <= LPRsup g.
Proof. 
intros. apply LPRsup_monotonic_gen. intros. exists a. auto.
Qed.

Lemma LPRsup_eq_pointwise {A : Type} (f g : A -> LPReal)
  : (forall (a : A), f a = g a) -> LPRsup f = LPRsup g.
Proof.
intros mono.
apply LPReq_compat. split; apply LPRsup_monotonic;
intros; rewrite mono; apply LPRle_refl.
Qed.

Lemma LPRsup_sum {A : Type} (f g : A -> LPReal)
  : LPRsup (fun x => f x + g x) <= LPRsup f + LPRsup g.
Proof. apply LPRsup_le. intros a.
apply LPRplus_le_compat; apply LPRsup_ge.
Qed.

Lemma LPRsup_sum_lattice {A : Type} (f g : A -> LPReal)
  (le : A -> A -> Prop)
  (max : A -> A -> A)
  (maxL  : forall (a b : A), le a (max a b))
  (maxR  : forall (a b : A), le b (max a b))
  (monof : forall n m, le n m -> f n <= f m)
  (monog : forall n m, le n m -> g n <= g m)
  : LPRsup (fun x => f x + g x) = LPRsup f + LPRsup g.
Proof.
apply LPReq_compat. split; [apply LPRsup_sum | ].
unfold LPRle. intros. simpl in *.
destruct H; simpl in *.
- destruct H. exists x. apply LPRplusL. assumption.
- destruct H. exists x. apply LPRplusR. assumption.
- destruct H. destruct H0. exists (max x x0). eapply LPRplusB.
  eapply monof. apply maxL. eassumption.
  eapply monog. apply maxR. eassumption. assumption.
Qed.

Lemma LPRsup_nat_ord (f g : nat -> LPReal)
  : (forall n m, (n <= m)%nat -> f n <= f m)
  -> (forall n m, (n <= m)%nat -> g n <= g m)
  -> LPRsup (fun x => f x + g x) = LPRsup f + LPRsup g.
Proof. intros. eapply LPRsup_sum_lattice; try eassumption.
apply Max.le_max_l.  apply Max.le_max_r.
Qed.

Definition LPRmax (x y : LPReal) : LPReal.
Proof. refine (
  {| lbound := fun q => x q \/ y q |}
).
- intros. destruct H; [left | right]; eapply dclosed; eassumption.
- intros. destruct H; 
  pose proof (uopen _ _ H) as H'; 
  destruct H' as [q' [qq' pq']]; exists q'; intuition.
Defined.

Lemma LPRmax_le_and {x y z : LPReal} 
  : x <= z -> y <= z -> LPRmax x y <= z.
Proof. intros.
unfold LPRle; simpl in *; intros; intuition.
Qed.

Lemma LPRmax_le_or {x y z : LPReal} 
  : z <= x \/ z <= y -> z <= LPRmax x y.
Proof. intros.
unfold LPRle; simpl in *; intros; intuition.
Qed.

Definition LPRmin (x y : LPReal) : LPReal.
Proof. refine (
  {| lbound := fun q => x q /\ y q |}
).
- intros. destruct H; split; eapply dclosed; eassumption.
- intros. destruct H. 
  destruct (uopen _ _ H) as [q'x [qq'x pq'x]].
  destruct (uopen _ _ H0) as [q'y [qq'y pq'y]].
  exists (Qnnmin q'x q'y). split. eapply Qnnmin_lt_both; assumption.
  split; eapply dclosed; try eassumption. apply Qnnmin_l.
  apply Qnnmin_r.
Defined.

Theorem LPRle_antisym {x y : LPReal}
  : x <= y -> y <= x -> x = y.
Proof.
intros. apply LPReq_compat. split; assumption.
Qed.

(* constant function *)
Definition K {A} (x : A) {B} (y : B) := x.

(* Here's the analogy:
  Valuation : Measure :: constructive logic : classical logic

A good reference:

Claire Jones. Probabilistic Nondeterminism. 1990. Phd Thesis.
https://www.era.lib.ed.ac.uk/handle/1842/413
*)

Record Valuation {A : Type} :=
  { val :> (A -> Prop) -> LPReal
  ; strict : val (K False) = 0
  ; monotonic : forall (U V : A -> Prop), (forall z, U z -> V z)
              -> val U <= val V
  ; modular : forall {U V},
     val U + val V = val (fun z => U z /\ V z) + val (fun z => U z \/ V z)
  }.

Arguments Valuation : clear implicits.

Definition pointwise {A B : Type} (cmp : B -> B -> Prop)
  (f g : A -> B) : Prop := forall (a : A), cmp (f a) (g a).

(** An inductive definition of simple functions. I hesitate to
    call them functions because they aren't necessarily computable.
    I'm using "max" instead of "plus", because I believe it's
    equivalent, and makes formulating certain things easier. *)
Inductive Simple {A : Type} :=
  | SStep : LPReal -> (A -> Prop) -> Simple
  | SMax : Simple -> Simple -> Simple.

Arguments Simple : clear implicits.

(* Definition of how to integrate simple functions *)
Fixpoint SimpleIntegral {A : Type} (mu : (A -> Prop) -> LPReal) 
  (s : Simple A) : LPReal := match s with
  | SStep c P => c * mu P
  | SMax f g => LPRmax (SimpleIntegral mu f) (SimpleIntegral mu g)
  end.

(* An real number which is an indicator for a logical proposition.
   It is 0 if P is false and 1 if P is true. Without a proof or
   refutation of P, you will not know which! *)
Definition LPRindicator (P : Prop) : LPReal.
Proof. refine 
( {| lbound := fun q => P /\ (q < 1)%Qnn |}).
- intros. intuition. eapply Qnnle_lt_trans; eassumption. 
- intros. destruct H. pose proof (Qnnbetween q 1%Qnn H0).
  destruct H1. exists x. intuition.
Defined.

Lemma LPRind_bounded (P : Prop) : LPRindicator P <= 1.
Proof.
unfold LPRle; intros; simpl in *; intuition.
Qed.

Lemma LPRind_imp (P Q : Prop) (f : P -> Q)
  : LPRindicator P <= LPRindicator Q.
Proof.
unfold LPRle; intros; simpl in *. intuition.
Qed.

Lemma LPRind_iff (P Q : Prop) (equiv : P <-> Q)
  : LPRindicator P = LPRindicator Q.
Proof.
apply LPReq_compat; split;
unfold LPRle; intros; simpl in *; intuition.
Qed.

Lemma LPRind_true (P : Prop) : P -> LPRindicator P = 1.
Proof. intros. apply LPReq_compat.
split.
- apply LPRind_bounded.
- unfold LPRle; intros; simpl in *. intuition.
Qed.

Lemma LPRind_false (P : Prop) : ~ P -> LPRindicator P = 0.
Proof. intros. apply LPReq_compat. 
split.
- unfold LPRle; intros; simpl in *. intuition.
- apply LPRzero_min.
Qed.

Hint Resolve Qnnle_refl.

Lemma LPRind_scale_le {P : Prop} {x y : LPReal}
  : (P -> x <= y) -> LPRindicator P * x <= y.
Proof.
intros. unfold LPRle; simpl in *; intros.
destruct H0 as [a [b [pa [pb ab]]]].
destruct pa. apply H in H0. apply H0. eapply dclosed. 
eassumption. eapply Qnnle_trans. eassumption.
replace b with (1 * b)%Qnn at 2 by ring.
apply Qnnmult_le_compat. apply Qnnlt_le_weak. assumption.
apply Qnnle_refl.
Qed.

Lemma qnn_sqrt {x : Qnn}
  : (x < 1)%Qnn -> exists y, (y < 1 /\ x <= y * y)%Qnn.
Proof.
Admitted.

Lemma LPRind_mult {U V : Prop}
  : LPRindicator (U /\ V) = LPRindicator U * LPRindicator V.
Proof.
apply LPReq_compat. 
split; unfold LPRle; simpl in *; intros.
- intuition. pose proof (qnn_sqrt H1). 
  destruct H0. exists x. exists x. intuition.
- destruct H as [a [b [pa [pb ab]]]]. intuition.
  eapply Qnnle_lt_trans. eassumption.
  apply Qnnle_lt_trans with (a * 1)%Qnn.
  apply Qnnmult_le_compat. apply Qnnle_refl.
  apply Qnnlt_le_weak. assumption. 
  replace 1%Qnn with (1 * 1)%Qnn at 2 by ring. 
  apply Qnnmult_lt_compat_r. apply Qnnlt_alt. reflexivity.
  assumption.
Qed.

Lemma LPRind_max {U V : Prop}
  : LPRindicator (U \/ V) = LPRmax (LPRindicator U) (LPRindicator V).
Proof.
apply LPReq_compat.
split; unfold LPRle; simpl in *; intros; intuition.
Qed.

Lemma LPRind_min {U V : Prop}
  : LPRindicator (U /\ V) = LPRmin (LPRindicator U) (LPRindicator V).
Proof.
apply LPReq_compat.
split; unfold LPRle; simpl in *; intros; intuition.
Qed.

Lemma LPRind_modular {U V : Prop} :
   LPRindicator U + LPRindicator V =
   LPRindicator (U /\ V) + LPRindicator (U \/ V).
Proof.
apply LPReq_compat; split; unfold LPRle; intros q H.
- destruct H.
  + apply LPRplusR. rewrite LPRind_max. left. assumption.
  + apply LPRplusR. rewrite LPRind_max. right. assumption.
  +  simpl in *. intuition. eapply LPRplusB. rewrite LPRind_min.
     simpl in *. intuition.  apply H3. apply H3. rewrite LPRind_max.
     simpl. right. split. apply H. apply H4. assumption.
- destruct H.
  + eapply LPRplusB; simpl in *; intuition. eassumption. eassumption.
    replace q with (q + 0)%Qnn at 1 by ring.
    apply Qnnplus_le_compat. apply Qnnle_refl. apply nonneg.
  + simpl in *. destruct H. destruct H. 
    * apply LPRplusL. simpl. intuition.
    * apply LPRplusR. simpl. intuition.
  + simpl in *. eapply LPRplusB; simpl in *; intuition.
    eapply H3. assumption. eapply H4. assumption. assumption.
    assumption.
Qed.

(* The equivalent of a Dirac delta for a given point.
   Called `unit` because Valuations form a mona, and
   this is the unit. *)
Definition unit {A : Type} (a : A) : Valuation A.
Proof. refine (
 {| val := fun P => LPRindicator (P a) |}
); intros.
- apply LPRind_false. auto.
- apply LPRind_imp. apply H.
- apply LPRind_modular.
Defined.

(* Here we consider a Simple as a pointwise function, in a sense,
   by integrating against a Dirac delta. *)
Definition SimpleEval {A : Type} (f : Simple A) (x : A) : LPReal :=
  SimpleIntegral (unit x) f.

Definition integral {A : Type} (f : A -> LPReal) (mu : Valuation A) :=
  LPRsup (fun (pr : { s | pointwise LPRle (SimpleEval s) f}) =>
      SimpleIntegral mu (proj1_sig pr)).

Axiom int_simple_ge : forall {A : Type} {s : Simple A} {f : A -> LPReal} {mu : Valuation A},
      pointwise LPRle f (SimpleEval s)
    -> integral f mu <= SimpleIntegral mu s.

Lemma int_monotonic : forall {A : Type} {f g : A -> LPReal}
     , pointwise LPRle f g -> forall (mu : Valuation A)
     , integral f mu <= integral g mu.
Proof. intros. unfold integral. apply LPRsup_monotonic_gen.
intros. destruct a. assert (pointwise LPRle (SimpleEval x) g).
unfold pointwise in *. intros. eapply LPRle_trans. apply p. apply H.
exists (exist _ x H0). simpl. apply LPRle_refl.
Qed.

Lemma int_adds {A : Type} : forall {f g : A -> LPReal} {mu : Valuation A}
     , integral f mu + integral g mu = integral (fun x => f x + g x) mu.
Proof. Admitted.

Lemma int_scales {A : Type} : forall {c : LPReal} {f : A -> LPReal} {mu : Valuation A}
     , c * integral f mu = integral (fun x => c * f x) mu.
Proof. Admitted.

Lemma int_simple_le {A : Type} :
forall {s : Simple A} {f : A -> LPReal} {mu : Valuation A},
      pointwise LPRle (SimpleEval s) f
    ->  SimpleIntegral mu s <= integral f mu.
Proof. intros.
pose (exist (fun s' => pointwise LPRle (SimpleEval s') f) s H).
eapply LPRle_trans. Focus 2.
simpl. eapply LPRsup_ge.
instantiate (1 := s0). simpl.
apply LPRle_refl.
Qed.

Lemma int_simple {A : Type} {s : Simple A} {mu : Valuation A}
  : integral (SimpleEval s) mu = SimpleIntegral mu s.
Proof.
apply LPReq_compat.
split; [apply int_simple_ge | apply int_simple_le]
  ; unfold pointwise; intros a; apply LPRle_refl.
Qed.

(** Pushforward of a measure, i.e., map a function over a measure *)
Definition map {A B : Type} (f : A -> B) (v : Valuation A)
  : Valuation B.
Proof. refine (
  {| val := fun prop => val v (fun x => prop (f x)) |}
); intros.
- apply strict.
- apply monotonic. auto.
- apply modular; auto.
Defined.

Lemma qredistribute : forall andLq andRq orLq orRq,
    andLq + andRq + (orLq + orRq)
 = (andLq + orLq) + (andRq + orRq).
Proof. intros. ring. Qed.

Lemma LPRplus_eq_compat : forall x y x' y',
  x = x' -> y = y' -> x + y = x' + y'.
Proof. intros. subst. reflexivity. Qed.

(** The sum of two valuations *)
Definition add {A : Type} (ValL ValR : Valuation A) : Valuation A.
Proof. refine (
  {| val := fun P => ValL P + ValR P |}
); intros.
- rewrite strict. rewrite strict. ring.
- apply LPRplus_le_compat; apply monotonic; assumption.
- rewrite qredistribute. 
  rewrite (qredistribute (ValL (fun z => U z /\ V z))).
  apply LPRplus_eq_compat; apply modular.
Defined.

Lemma LPRmult_eq_compat : forall x y x' y',
  x = x' -> y = y' -> x * y = x' * y'.
Proof. intros. subst. reflexivity. Qed.

(* Scale a valuation by a constant *)
Definition scale {A : Type} (c : LPReal) 
  (Val : Valuation A) : Valuation A.
Proof. refine (
  {| val := fun P => c * Val P |}
); intros.
- rewrite strict. ring.
- apply LPRmult_le_compat. apply LPRle_refl.
  apply monotonic; assumption.
- replace (c * Val U + c * Val V) with (c * (Val U + Val V)) by ring.
  replace (c * Val _ + c * Val _) 
  with (c * (Val (fun z : A => U z /\ V z) + Val (fun z : A => U z \/ V z))) by ring.
  apply LPRmult_eq_compat. reflexivity.
  apply modular.
Defined.

(* The valuation which is 0 everywhere *)
Definition zeroVal {A : Type} : Valuation A.
Proof. refine (
  {| val := fun P => 0 |}
).
- reflexivity.
- intros. apply LPRle_refl.
- intros. reflexivity.
Defined.

Definition Valle {A : Type} (val1 val2 : Valuation A) : Prop :=
  forall (P : A -> Prop), val1 P <= val2 P.

Lemma Valle_refl {A : Type} (val : Valuation A) : Valle val val.
Proof. unfold Valle. intros. apply LPRle_refl. Qed.

Lemma Valle_trans {A : Type} (x y z : Valuation A)
  : Valle x y -> Valle y z -> Valle x z.
Proof. intros. unfold Valle in *. intros P.
eapply LPRle_trans. apply H. apply H0.
Qed.

Definition Valeq {A : Type} (val1 val2 : Valuation A) : Prop :=
  forall (P : A -> Prop), val1 P = val2 P.

Lemma Valle_antisym {A : Type} (x y : Valuation A)
  : Valle x y -> Valle y x -> Valeq x y.
Proof. intros. unfold Valle, Valeq in *. intros.
apply LPRle_antisym. apply H. apply H0.
Qed.

Lemma Valeq_compat_OK 
  (proof_irrel : forall (P : Prop) (x y : P), x = y)
  { A : Type }
  : forall (mu nu : Valuation A), Valeq mu nu -> mu = nu. 
Proof.
intros.
unfold Valeq in *.
destruct mu, nu. simpl in *.
assert (val0 = val1).
apply functional_extensionality. assumption.
induction H0.
pose proof (proof_irrel _ strict0 strict1).
induction H0.
pose proof (proof_irrel _ monotonic0 monotonic1).
induction H0.
pose proof (proof_irrel _ modular0 modular1).
induction H0.
reflexivity.
Qed.

Axiom Valeq_compat : forall (A : Type) (mu nu : Valuation A)
  , Valeq mu nu -> mu = nu.

Lemma Valplus_comm {A : Type} : forall {x y : Valuation A}
  , add x y = add y x.
Proof.
intros. apply Valeq_compat.
unfold Valeq. intros. simpl. ring.
Qed.

Definition Valge {A : Type} (x y : Valuation A)
  := Valle x y.

Infix "<=" := Valle : Val_scope.
Infix ">=" := Valge : Val_scope.
Infix "+" := add : Val_scope.
Infix "*" := scale : Val_scope.

Notation "'0'" := zeroVal : Val_scope.

Delimit Scope Val_scope with Val.

Definition pchoice {A : Type} (p q : LPReal)
  (mu mu' : Valuation A) : Valuation A
  := (p * mu + q * mu')%Val.

Lemma pchoice_prob {A : Type} {p q : LPReal}
  {mu mu' : Valuation A} :
    (p + q = 1) -> mu (K True) = 1 -> mu' (K True) = 1
  -> (pchoice p q mu mu') (K True) = 1.
Proof.
intros. unfold pchoice. simpl. rewrite H0. rewrite H1.
replace (p * 1 + q * 1) with (p + q) by ring.
assumption.
Qed.

Require Fin Vector.

Fixpoint uniform_helper {A : Type} (p : LPReal) (xs : list A) := match xs with
  | nil => 0%Val
  | (x :: xs')%list => (p * unit x + uniform_helper p xs')%Val
end.

Lemma LPRQnn_eq {x y : Qnn} : x = y -> LPRQnn x = LPRQnn y.
Proof. intros; subst; reflexivity. Qed.

Lemma uniform_helper_weight {A : Type} {p : LPReal} {xs : list A}
  : uniform_helper p xs (K True) = LPRQnn (Qnnnat (length xs)) * p.
Proof.
induction xs. 
- simpl. ring. 
- simpl. rewrite LPRind_true by (unfold K; trivial).
  rewrite IHxs.
  rewrite <- LPRQnn_plus. ring.
Qed.

Definition uniform {A : Type} {n : nat} (xs : Vector.t A (S n)) :=
  uniform_helper (LPRQnn (Qnnfrac (S n))) (Vector.to_list xs).

Lemma Vector_length {A : Type} {n : nat} {xs : Vector.t A n}
  : length (Vector.to_list xs) = n.
Proof. induction xs.
- reflexivity.
- unfold Vector.to_list in *. simpl. rewrite IHxs. reflexivity.
Qed.

Lemma LPRQnn_mult {x y : Qnn} : LPRQnn x * LPRQnn y = LPRQnn (x * y)%Qnn.
Proof. 
Admitted.


Lemma uniform_prob {A : Type} : forall {n : nat} {xs : Vector.t A (S n)}
  , (uniform xs) (K True) = 1.
Proof.
intros. unfold uniform.
rewrite uniform_helper_weight. rewrite Vector_length.
rewrite LPRQnn_mult. rewrite Qnnnatfrac. reflexivity.
Qed.

Lemma integral_zero {A : Type} : forall {mu : Valuation A} (c : LPReal)
  , integral (SimpleEval (SStep c (K False))) mu = 0.
Proof.
intros.
rewrite int_simple. simpl. 
replace (mu (K False)) with 0. ring. symmetry. apply strict.
Qed.

Lemma func_pointwise_eq {A : Type} {f g : A -> LPReal}
  : pointwise LPReq f g -> f = g.
Proof. intros. apply functional_extensionality.
intros. apply LPReq_compat. apply H. Qed.

(* If two functions are equal at every point, then
   they integrate to the same thing. *)
Lemma int_pointwise_eq {A : Type} : 
  forall (f g : A -> LPReal), pointwise LPReq f g ->
  forall (mu : Valuation A),
  integral f mu = integral g mu.
Proof. intros. replace g with f. reflexivity. apply func_pointwise_eq.
apply H.
Qed.

(** The "bind" of our monad. Given a measure over the space A, and a
    function which, given a point in A, returns a measure on B,
    we can produce a measure on B by integrating over A. *)
Definition bind {A B : Type}
  (v : Valuation A) (f : A -> Valuation B)
  : Valuation B.
Proof. refine (
  {| val := fun P => integral (fun x => (f x) P) v |}
).
- apply LPReq_compat. unfold LPReq. split.
  erewrite <- integral_zero.
  apply int_monotonic.
  unfold pointwise. intros.
  instantiate (1 := 0).
  rewrite strict. apply LPRzero_min.
  apply LPRzero_min.
- intros. apply int_monotonic.
  unfold pointwise. intros.
  apply monotonic. assumption.
- intros. do 2 rewrite int_adds. apply int_pointwise_eq.
  unfold pointwise. intros a.
  assert (
((f a) U + (f a) V) =
((f a) (fun z : B => U z /\ V z) + (f a) (fun z : B => U z \/ V z))
). apply modular. rewrite H. split; apply LPRle_refl.
Defined.

(* Product measures. That is, the joint distribute for two
   independent measures. *)
Definition product {A B : Type}
  (muA : Valuation A) (muB : Valuation B)
  : Valuation (A * B) := 
  bind muA (fun a => map (fun b => (a, b)) muB).

Theorem int_dirac_simple {A : Type} {s : Simple A} {a : A} :
 SimpleIntegral (unit a) s = SimpleEval s a.
Proof.
unfold SimpleEval. induction s; simpl; reflexivity.
Qed.

Theorem int_indicator {A : Type} {P : A -> Prop} {mu : Valuation A}
  : integral (fun x => LPRindicator (P x)) mu = mu P.
Proof.
rewrite int_pointwise_eq with (g := SimpleEval (SStep 1 P)).
rewrite int_simple. simpl. ring.
unfold SimpleEval. simpl. 
unfold pointwise. intros. apply LPReq_compat_backwards. ring.
Qed.


Theorem int_dirac_test {A : Type} {f : A -> LPReal} {a : A}
  (s : Simple A)
  : pointwise LPRle (SimpleEval s) f
  -> integral (SimpleEval s) (unit a) <= f a.
Proof.
intros. rewrite int_simple. rewrite int_dirac_simple. apply H. 
Qed.

Lemma undo_proj1sig {A : Type} {B : A -> Prop} 
  (a : A) (b : B a) : proj1_sig (exist _ a b) = a.
Proof. reflexivity. Qed.


Fixpoint map_Simple {A B : Type} 
  (f : A -> B) (s : Simple B) : Simple A
  := match s with
  | SStep c P => SStep c (fun x => P (f x))
  | SMax l r => SMax (map_Simple f l) (map_Simple f r)
  end.

Lemma map_SimpleIntegral {A B : Type}
  {s : Simple B} {f : A -> B}
  { mu : Valuation A}
  : SimpleIntegral mu (map_Simple f s) 
  = SimpleIntegral (map f mu) s. 
Proof.
induction s; intros.
- simpl. reflexivity.
- simpl in *. rewrite IHs1. rewrite IHs2. reflexivity.
Qed.

Lemma change_of_variables {A B : Type}
  {mu : Valuation A} {f : A -> B} {g : B -> LPReal}
  : integral (fun x => g (f x)) mu
  = integral g (map f mu).
Proof.
unfold integral. apply LPReq_compat. split.
- admit.
- apply LPRsup_le; intros simp;
  destruct simp as [s sle]; simpl.
  apply LPRsup_ge2. eexists. rewrite undo_proj1sig.
  rewrite (@map_SimpleIntegral _ _ s f). apply LPRle_refl.
Grab Existential Variables.
simpl. unfold SimpleEval, pointwise in *. intros a.
rewrite map_SimpleIntegral. apply (sle (f a)).
Qed.

Definition MeasurableR {A : Type} (f : A -> LPReal)
  := forall (eps : Qnn), (eps > 0)%Qnn
   -> exists (s : Simple A)
   , pointwise LPRle (SimpleEval s) f
   /\ pointwise LPRle f (fun x => SimpleEval s x + LPRQnn eps).

Lemma MeasurableRSimple {A : Type} (s : Simple A)
  : MeasurableR (SimpleEval s).
Proof.
unfold MeasurableR. intros. exists s. split; unfold pointwise; intros a.
apply LPRle_refl. replace (SimpleEval s a) with (SimpleEval s a + 0)
  at 1 by ring. apply LPRplus_le_compat. apply LPRle_refl.
  apply LPRzero_min.
Qed.

Definition Measurable {A B : Type} (f : A -> B)
  := forall (g : B -> LPReal), MeasurableR g -> MeasurableR (fun x => g (f x)).

Lemma Measurable_id {A : Type}
  : Measurable (fun x : A => x).
Proof. unfold Measurable. intros.  apply H.
Qed.

Lemma Measurable_compose {A B C : Type}
  {f : A -> B} {g : B -> C}
  : Measurable f -> Measurable g -> Measurable (fun x => g (f x)).
Proof.
intros. unfold Measurable in *. intros.
apply (H (fun x => g0 (g x))).
apply H0. assumption.
Qed.


(* Integrating a function over a Dirac delta results in
   simply the function value at that point. *)
Theorem int_dirac {A : Type} {f : A -> LPReal} {a : A}
  : integral f (unit a) = f a.
Proof.
intros.
pose (s := SStep (f a) (fun a' => a = a')).
  unfold integral. eapply LPRsup_prop.
- intros pr. destruct pr. simpl. 
  replace (fun P => LPRindicator (P a)) with (val (unit a)) by reflexivity.
  rewrite int_dirac_simple. apply p.
- eexists. rewrite undo_proj1sig.
  instantiate (1 := s).
  rewrite int_dirac_simple. unfold SimpleEval; simpl.
  rewrite LPRind_true by reflexivity.
  replace (f a * 1) with (f a) by ring.
  apply LPRle_refl.
  Grab Existential Variables.
  simpl. unfold pointwise. intros. unfold SimpleEval.
  simpl. rewrite (SRmul_comm LPRsrt). apply LPRind_scale_le.
  intros H. induction H. apply LPRle_refl.
Qed. 

(* We get what we would expect if we take the product of a
   Dirac delta with another distribution. *)
Theorem unitProdId {A B : Type}
  (a : A) (muB : Valuation B) (P : (A * B) -> Prop)
  : product (unit a) muB P = muB (fun b => P (a, b)).
Proof. simpl. rewrite int_dirac. reflexivity. Qed.

(* Product measures factor in the expected way. *)
Theorem product_prop {A B : Type}
  (muA : Valuation A)
  (muB : Valuation B)
  (PA : A -> Prop) (PB : B -> Prop)
  : (product muA muB) (fun p => let (x, y) := p in PA x /\ PB y)
  = muA PA * muB PB.
Proof. simpl.
rewrite <- int_indicator.
rewrite (SRmul_comm LPRsrt).
rewrite int_scales.
apply int_pointwise_eq. unfold pointwise.
intros a.
do 2 rewrite <- int_indicator.
rewrite (SRmul_comm LPRsrt).
rewrite int_scales.
eapply LPReq_compat_backwards.
apply int_pointwise_eq.
unfold pointwise. intros.
rewrite LPRind_mult.
apply LPReq_refl.
Qed.

(** WARNING: Work in progress from here on out! *)

Require Vector.

(** An n-fold IID product of a given measure. *)
Fixpoint product_n {A : Type} (v : Valuation A)
  (n : nat) : Valuation (Vector.t A n) := match n with
  | 0 => unit (Vector.nil A)
  | S n' => bind v (fun x => map (Vector.cons A x n') (product_n v n'))
  end.

Fixpoint product_n2 {A : Type} (v : Valuation A)
  (n : nat) {struct n} : Valuation (Vector.t A n) := match n with
  | 0 => unit (Vector.nil A)
  | S n' => bind (product_n v n') (fun xs => map (fun x => Vector.shiftin x xs) v)
  end.

Lemma commute_cons_shiftin {A : Type} {n : nat}
  : forall {xs : Vector.t A n} {a z : A},
    Vector.cons A a _ (Vector.shiftin z xs)
  = Vector.shiftin z (Vector.cons A a _ xs).
Proof.
destruct n; reflexivity.
Qed.

Theorem product_n_same {A : Type} {v : Valuation A}
  {n : nat}
  : product_n v n = product_n2 v n.
Proof.
induction n; apply Valeq_compat; unfold Valeq; intros.
- simpl. reflexivity. 
- simpl.
assert (
    (fun x : A =>
      (product_n v n) (fun x0 : Vector.t A n => P (Vector.cons A x n x0)))
=
    (fun x : A =>
      (product_n2 v n) (fun x0 : Vector.t A n => P (Vector.cons A x n x0)))
).
apply functional_extensionality. intros. rewrite IHn. reflexivity.
rewrite H. clear H.
rewrite IHn.
Abort.

Require Streams.

Fixpoint take_n {A : Type} (s : Streams.Stream A) (n : nat)
  : Vector.t A n := match n, s with
  | 0, _ => Vector.nil A
  | S n', Streams.Cons x xs => Vector.cons A x n' (take_n xs n')
end.

(* Restrict a property of streams to a property of vectors of length n.
   The property is true for a vector of length in if the property is
   true for ALL streams which begin with that finite prefix. *)
Definition restrictToVec {A : Type} (P : Streams.Stream A -> Prop)
  (n : nat) (x : Vector.t A n) : Prop :=
  forall (s : Streams.Stream A), take_n s n = x -> P s.

Lemma restrictToVecBot {A : Type} {n : nat}
  (nonempty : A)
  : forall xs, ~ (@restrictToVec A (K False) n xs).
Proof. Admitted.

Lemma restrictToVecMonotonicP {A : Type} {n : nat}
  : forall { U V : Streams.Stream A -> Prop }
  , (forall (s : Streams.Stream A), U s -> V s)
  -> forall xs, restrictToVec U n xs -> restrictToVec V n xs.
Proof.
intros. unfold restrictToVec in *.
intros s take. apply H. apply H0. assumption.
Qed.

Lemma restrictToVecMonotonicN {A : Type} : 
 forall (v : Valuation A) (U : Streams.Stream A -> Prop),
 v (K True) = 1 ->
 forall n m : nat,
 (n <= m)%nat ->
 (product_n v n) (restrictToVec U n) <=
 (product_n v m) (restrictToVec U m).
Proof. intros. generalize dependent U.
induction H0; intros. apply LPRle_refl.
simpl.
eapply LPRle_trans. apply IHle.
rewrite <- int_indicator in H.
replace ((product_n v m) (restrictToVec U m))
   with ((product_n v m) (restrictToVec U m) * 1) by ring.
rewrite <- H.
rewrite int_scales.
apply int_monotonic.
unfold pointwise. intros a. unfold K.
rewrite LPRind_true by trivial.
replace ((product_n v m) (restrictToVec U m) * 1)
   with ((product_n v m) (restrictToVec U m)) by ring.
(* should see that we can snoc instead of cons and get the
   same measure *)
apply monotonic. intros.
admit.
Qed.

Lemma valPosNonEmpty {A : Type} {mu : Valuation A}
  (P : A -> Prop) (pos : mu P > 0)
  : ((A -> False) -> False).
Proof.
intros. 
pose proof (strict mu).
rewrite <- H0 in pos.
assert (~ (forall x, P x = (K False) x)).
unfold not. intros.
apply functional_extensionality in H1.
rewrite H1 in pos. 
unfold LPRgt in pos. unfold LPRlt in pos.
destruct pos. destruct H2. apply H2 in H3.
assumption.
apply H1. intros. apply False_rect. apply H. assumption.
Qed.

(* An infinite product measure, generated by considering finite
   products and taking the limit. *)
Theorem inf_product {A : Type} (v : Valuation A)
  (nonempty : A)
  (vIsProb : v (K True) = 1)
  : Valuation (Streams.Stream A).
Proof.
refine (
  {| val := fun P => LPRsup (fun n => (product_n v n) (restrictToVec P n))
  |}
); intros.
- apply LPReq_compat. split; [| apply LPRzero_min].
  unfold LPRle. simpl. intros. destruct H.
  apply (monotonic _ _ (K False)) in H.
  rewrite (strict (product_n v x)) in H.
  simpl in H. assumption.
  apply restrictToVecBot.
  apply nonempty.
- apply LPRsup_monotonic.
  intros n. induction n; simpl.
  + apply LPRind_imp.
    unfold restrictToVec. intros H1.
    intros. apply H. apply H1. apply H0.
  + apply int_monotonic. unfold pointwise.
    intros a. apply monotonic. intros.
    eapply restrictToVecMonotonicP. eassumption.
    assumption.
- do 2 (rewrite <- LPRsup_nat_ord; 
  try (apply restrictToVecMonotonicN);
  try assumption).
  (* apply modular. *)
  admit.
Defined.

(** A datatype for partial computations. We will use this
    to allow definitions of measures which might not be guaranteed
    to terminate. For example, consider the geometric distribution,
    where we might worry that we keep getting "heads". *)
CoInductive Partial {A : Type} : Type :=
 | Now : A -> Partial
 | Later : Partial -> Partial.

(** We can use this to loop. *)
CoFixpoint loop {A : Type} := @Later A loop.

Arguments Partial : clear implicits.

(** The nth iteration of the fixpoint of a functional on
    measures *)
Fixpoint fixn {A : Type}
  (f : Valuation A -> Valuation A) (n : nat)
  : Valuation A
  := match n with
  | 0 => zeroVal
  | S n' => f (fixn f n')
  end.

(* Run a partial computation for n steps, returning the value if
   we got a value in that many steps or fewer. *)
Fixpoint runPartial {A : Type} (px : Partial A)
  (n : nat) : option A := match px with
  | Now x => Some x
  | Later px' => match n with
    | 0 => None
    | S n' => runPartial px n'
    end 
  end.

(* Transform a property of values of A to a property of partial computations
   which may return an A, where the new property is true only if the computation
   indeed eventually returns a value for which the original property was true. *)
Definition partialize {A : Type} (P : A -> Prop)
  (px : Partial A) : Prop := exists n, match runPartial px n with
  | None => False
  | Some x => P x
  end.

Lemma partial_now {A : Type} (a : A) (n : nat)
  : runPartial (Now a) n = Some a.
Proof. induction n; unfold runPartial; intuition. Qed. 

Lemma partial_mono {A : Type} : forall (m n : nat) (px : Partial A)
  (a : A), (m <= n)%nat -> runPartial px m = Some a -> runPartial px n = Some a.
Proof.
intros. induction H. assumption. simpl. rewrite IHle.
  destruct px. simpl in *. rewrite partial_now in H0. assumption.
  reflexivity.
Qed.

Lemma partialize_and {A : Type} {U V : A -> Prop}
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  : partialize (fun z => U z /\ V z) 
  = fun z => partialize U z /\ partialize V z.
Proof. apply functional_extensionality.
intros. apply propext. split; intros;
unfold partialize in *. destruct H;
split; exists x0; destruct (runPartial x x0); intuition.
destruct H. destruct H. destruct H0.
exists (max x0 x1). destruct (runPartial x x0) eqn:p0;
  destruct (runPartial x x1) eqn:p1; try contradiction.
  apply partial_mono with (n := max x0 x1) in p0.
  apply partial_mono with (n := max x0 x1) in p1.
  rewrite p0 in p1. injection p1. intros. subst.
  rewrite p0. split; assumption.
  apply Max.le_max_r. apply Max.le_max_l.
Qed.

Lemma partialize_or {A : Type} {U V : A -> Prop}
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  : partialize (fun z => U z \/ V z) 
  = fun z => partialize U z \/ partialize V z.
Proof. apply functional_extensionality.
intros. apply propext. split; intros;
unfold partialize in *. destruct H.
destruct (runPartial x x0) eqn:partial.
destruct H; [left | right]; exists x0;
rewrite partial; assumption. contradiction.
destruct H; destruct H; exists x0;
destruct (runPartial x x0) eqn:partial; intuition.
Qed.

(** We can convert a measure on [Partial A]s to a measure on 
    [A]s by essentially just setting measure 0 to any of the
    values which never terminated. *)
Definition partialValuation {A : Type}
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  (v : Valuation (Partial A))
  : Valuation A.
Proof. refine (
  {| val := fun P => v (partialize P) |}
).
- apply LPReq_compat. split. 
  + erewrite <- strict.
    apply monotonic. intros. unfold partialize, K in *.
    destruct H. destruct (runPartial z x); assumption.
  + apply LPRzero_min.
- intros.
  apply monotonic. intros z PU.
  unfold partialize in *. destruct PU.
  exists x. destruct (runPartial z x). apply H; assumption.
  assumption.
- intros. rewrite partialize_and. rewrite partialize_or.
  apply modular.
  apply propext. apply propext.
Defined.

(* If our valuation functional is monotonic, then the
   fixpoint is nondecreasing. *)
Lemma fixnmono {A : Type}
  (f : Valuation A -> Valuation A)
  (fmono : forall u v, Valle u v -> Valle (f u) (f v))
  : forall (n : nat), Valle (fixn f n) (fixn f (S n)).
Proof. intros. induction n.
simpl. unfold Valle; intros. simpl. apply LPRzero_min.
simpl. apply fmono. assumption.
Qed.

Lemma fixnmono2 {A : Type}
  (f : Valuation A -> Valuation A)
  (fmono : forall u v, Valle u v -> Valle (f u) (f v))
  : forall (m n : nat), (m <= n)%nat -> Valle (fixn f m) (fixn f n).
Proof. intros. induction H. apply Valle_refl. 
eapply Valle_trans. eassumption. apply fixnmono. assumption.
Qed.

(** If we have a valuation functional which is monotonic, we can take
    its fixpoint! *)
Definition fixValuation {A : Type}
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  (f : Valuation A -> Valuation A)
  (fmono : forall u v, Valle u v -> Valle (f u) (f v))
  : Valuation A.
Proof. refine (
  {| val := fun P => LPRsup (fun n => (fixn f n) P) |}
).
- apply LPReq_compat. split. 
  + apply LPRsup_le. intros. erewrite <- strict.
    apply monotonic. intros. assumption. 
  + apply LPRzero_min.
- intros. apply LPRsup_monotonic. intros n.
  apply monotonic. assumption. 
- intros.
  rewrite <- LPRsup_nat_ord by (intros; apply fixnmono2; assumption).
  rewrite <- LPRsup_nat_ord by (intros; apply fixnmono2; assumption).
  apply LPRsup_eq_pointwise. intros.
  apply modular.
Defined.

Lemma fixValuation_subProb {A : Type}
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  (f : Valuation A -> Valuation A)
  (fmono : forall u v, Valle u v -> Valle (f u) (f v))
  (fbounded : forall v, val v (K True) <= 1 -> f v (K True) <= 1)
  : (fixValuation propext f fmono) (K True) <= 1.
Proof. simpl. apply LPRsup_le.
intros n. induction n. simpl. apply LPRzero_min.
simpl. apply fbounded. assumption.
Qed.

(** The functional which corresponds to rejection sampling. *)
Definition rejectionFunc {A : Type} (v : Valuation A)
  (pred : A -> bool) 
  (f : Valuation A) : Valuation A :=
  bind v (fun a => if pred a
    then unit a
    else f).

(** This functional is indeed monotonic. *)
Lemma rejectionFunc_mono {A : Type} (v : Valuation A)
  (pred : A -> bool)
  : let f := rejectionFunc v pred 
    in forall mu1 mu2, Valle mu1 mu2 -> Valle (f mu1) (f mu2).
Proof. 
intros. unfold Valle in *. intros P. simpl.
apply int_monotonic. unfold pointwise. intros a.
destruct (pred a). apply LPRle_refl. apply H.
Qed.

(** Modify a measure by rejection sampling. *)
Definition rejection {A : Type} (v : Valuation A)
  (pred : A -> bool) 
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  : Valuation A
  := fixValuation propext (rejectionFunc v pred)
     (rejectionFunc_mono v pred).
 
Definition rejection_Prob_lemmaT {A : Type} (v : Valuation A)
  (pred : A -> bool) 
  (vProb : v (K True) = 1)
  (p : Qnn)
  (ple1 : (p <= 1)%Qnn)
  (predPos : v (fun x => pred x = true) p)
  (n : nat) :
 (fixn (rejectionFunc v pred) n) (K True) >= 
   (LPRQnn (Qnnminus 1%Qnn (p ^ n) (Qnnpow_le ple1))).
Proof. 
induction n. 
- simpl. apply LPRQnn_le. apply Qnnminus_le.
  replace (1 + 0)%Qnn with 1%Qnn by ring.
  apply Qnnle_refl.
-  simpl. 
Admitted. 

Lemma LPRsup_constant {A : Type} (x : LPReal) :
  A -> LPRsup (fun _ : A => x) = x.
Proof.
intros. apply LPReq_compat; split; unfold LPRsup, LPRle; simpl; intros.
destruct H. assumption. exists X. assumption. 
Qed.

Lemma smallPowers {p : Qnn} : (p < 1)%Qnn
  -> forall (q : Qnn), (q > 0)%Qnn 
  -> exists (n : nat), (p ^ n < q)%Qnn.
Admitted.

Lemma Qnnpowsup {p : Qnn} (plt1 : (p < 1)%Qnn)
  : LPRsup (fun n => LPRQnn (Qnnminus 1%Qnn (p ^ n) (Qnnpow_le (Qnnlt_le_weak plt1)))) = 1.
Proof. 
apply LPReq_compat. split.
- replace 1 with (LPRsup (fun _ : nat => 1)).
  apply LPRsup_monotonic. intros n. induction n; simpl.
   + unfold LPRle. simpl. intros. apply Qnnminus_lt_r in H.
     eapply Qnnle_lt_trans; [| eassumption].
     replace q with (0 + q)%Qnn at 1 by ring. apply Qnnplus_le_compat.
     apply nonneg. apply Qnnle_refl. 
   + unfold LPRle. simpl. intros. 
     apply LPRQnn_le in IHn. apply Qnnminus_lt_r in H.
     apply Qnnminus_le in IHn.
     eapply Qnnle_lt_trans. Focus 2. apply H.
     replace q with (0 + q)%Qnn at 1 by ring.
     apply Qnnplus_le_compat. apply nonneg. apply Qnnle_refl.
   + apply LPRsup_constant. exact 0%nat.
- unfold LPRle; simpl; intros.
  pose proof (smallPowers plt1 (Qnnminus 1%Qnn q (Qnnlt_le_weak H))).
  destruct (Qnn_dec q 0%Qnn).
  destruct s. apply Qnnlt_zero_prop in q0. contradiction.
  assert ((Qnnminus 1 q (Qnnlt_le_weak H) > 0)%Qnn).
  apply Qnnminus_lt_r. replace (q + 0)%Qnn with q by ring. assumption. 
  apply H0 in H1. destruct H1. exists x. apply Qnnminus_lt_r.
  apply Qnnminus_lt_r in H1. rewrite (SRadd_comm Qnnsrt).
  assumption. subst. exists 1%nat. simpl. apply Qnnminus_lt_r.
  replace (p * 1 + 0)%Qnn with p by ring. assumption.
Qed.

(** Rejection sampling gives a probability distribution if the
    predicate has a positive probability of occurence. *)
Definition rejection_Prob {A : Type} (v : Valuation A)
  (pred : A -> bool) 
  (vProb : v (K True) = 1)
  (predPos : v (fun x => pred x = true) > 0)
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  : (rejection v pred propext) (K True) = 1.
Proof.
apply LPReq_compat. split.
- apply fixValuation_subProb. intros. unfold rejectionFunc.
  simpl. rewrite <- vProb. rewrite <- int_indicator.
  apply int_monotonic. unfold pointwise. unfold K.
  intros. destruct (pred a). simpl.
  apply LPRind_imp. trivial.
  rewrite LPRind_true by trivial. apply H.
- unfold LPRle. destruct predPos as [p [Xp Pp]].
  intros. simpl in *.
  (* exists (1 - (1 - p)^n). *)
Abort. 

(** This is clearly wrong; this is just the zero measure. I even
    prove my wrongness a little bit further down. *)
Definition inf_productFunc {A : Type} (v : Valuation A)
  (f : Valuation (Streams.Stream A)) : Valuation (Streams.Stream A)
  := bind v (fun x => map (Streams.Cons x) f).

Lemma inf_productFunc_mono {A : Type} (v : Valuation A)
  : forall mu1 mu2, Valle mu1 mu2 -> Valle (inf_productFunc v mu1) (inf_productFunc v mu2).
Proof. 
intros. unfold Valle in *. intros P. simpl.
apply int_monotonic. unfold pointwise. intros a.
apply H.
Qed.

Definition inf_product' {A : Type} (v : Valuation A)
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  : Valuation (Streams.Stream A)
  := fixValuation propext (inf_productFunc v) (inf_productFunc_mono v).

Lemma inf_product'_wrong {A : Type} (v : Valuation A)
  (propext : forall (P Q : Prop), (P <-> Q) -> P = Q)
  : inf_product' v propext = zeroVal.
Proof.
apply Valeq_compat. unfold Valeq. intros P.
simpl. apply LPReq_compat. split.
apply LPRsup_le. intros n. generalize dependent P. induction n; intros.
simpl. apply LPRle_refl. simpl.
rewrite <- strict with v.
rewrite <- int_indicator. apply int_monotonic.
unfold pointwise. unfold K.
rewrite LPRind_false by intuition.
intros a. apply IHn. apply LPRzero_min.
Qed.

(** A data type for random samplers. [R] is the type of the random seed,
    and [A] is the type for which values are sampled. Our correctness property
    says that if we are given a seed which comes from the distribution [random]
    and then apply the sampling function [sample], the result is distributed as
    a new random seed distributed as [random] and a value of [A] distributed
    according to the measure [mu], and these two results are independent. *)
Record Sampler {R A : Type} (random : Valuation R) (mu : Valuation A)
  : Type :=
  { sample     :> R -> R * A
  ; sample_ind :  map sample random = product random mu
  }.

(** Samplers, too, form a monad, and here's the (very boring) unit. *)
Definition sunit {R A : Type} (random : Valuation R)
  (a : A) : Sampler random (unit a).
Proof. refine (
  {| sample := fun r => (r, a) |}
).
apply Valeq_compat. unfold Valeq. intros. simpl.
rewrite <- int_indicator. apply int_pointwise_eq.
unfold pointwise. intros r. apply LPReq_compat_backwards.
reflexivity.
Defined.

Lemma map_compose {A B C : Type} (mu : Valuation A)
  (g : B -> C) (f : A -> B)
  : map (fun x => g (f x)) mu = map g (map f mu).
Proof.
apply Valeq_compat. unfold Valeq. intros P.
simpl. reflexivity.
Qed.

Definition join {A : Type} (mu : Valuation (Valuation A))
  : Valuation A.
Proof. refine (
  {| val := fun P => integral (fun vA => val vA P) mu |}
).
- replace 0 with (0 * mu (K True)) by ring.
  rewrite <- int_indicator.
  rewrite int_scales.
  apply int_pointwise_eq. unfold pointwise. intros v.
  rewrite strict. apply LPReq_compat_backwards. ring.
- intros. apply int_monotonic. unfold pointwise.
  intros. apply monotonic. assumption.
- intros. rewrite int_adds. rewrite int_adds.
  apply int_pointwise_eq. unfold pointwise; intros.
  apply LPReq_compat_backwards. apply modular.
Defined.

(** Fubini's theorem about iterated integrals. It's likely _wrong_ as stated
    here, but it sure is useful! *)
Lemma fubini {A B : Type} (f : (A * B) -> LPReal)
  (muA : Valuation A) (muB : Valuation B)
 : integral (fun a => integral (fun b => f (a, b)) muB) muA
 = integral (fun b => integral (fun a => f (a, b)) muA) muB.
Proof.
Admitted.

Lemma fubini_curried {A B : Type} (f : A -> B -> LPReal)
  (muA : Valuation A) (muB : Valuation B)
 : integral (fun a => integral (fun b => f a b) muB) muA
 = integral (fun b => integral (fun a => f a b) muA) muB.
Proof.
pose (f' := fun p => f (fst p) (snd p)).
assert (
(fun a : A => integral (fun b : B => f a b) muB)
=
(fun a : A => integral (fun b : B => f' (a, b)) muB)
).
apply functional_extensionality. intros a.
apply int_pointwise_eq. unfold pointwise; intros b.
apply LPReq_compat_backwards. reflexivity.
rewrite H. clear H.

assert (
(fun b : B => integral (fun a : A => f a b) muA)
=
(fun b : B => integral (fun a : A => f' (a, b)) muA)
).
apply functional_extensionality. intros b.
apply int_pointwise_eq. unfold pointwise; intros a.
apply LPReq_compat_backwards. reflexivity.
rewrite H. clear H.
apply fubini.
Qed.

Lemma fubini_no_funext {A B : Type}
  (muA : Valuation A) (muB : Valuation B)
  {fA : A -> LPReal} {fB : B -> LPReal}
  {fAB : A -> B -> LPReal} {fBA : B -> A -> LPReal}
  : (forall a, integral (fAB a) muB = fA a)
  -> (forall b, integral (fBA b) muA = fB b)
  -> (forall a b, fAB a b = fBA b a)
  -> integral fA muA = integral fB muB.
Proof.
intros.
replace fA with (fun a => integral (fAB a) muB)
  by (apply functional_extensionality; assumption).
replace fB with (fun b => integral (fun a => fAB a b) muA).
Focus 2. apply functional_extensionality. 
intros. rewrite <- H0.
replace (fun a => fAB a x) with (fBA x).
Focus 2. apply functional_extensionality.
intros. symmetry. apply H1. 
reflexivity.
apply fubini_curried.
Qed.

Lemma bind_map_swap {A B C : Type}
  {muA : Valuation A} {muB : Valuation B}
  { f : A -> B -> C }
  : bind muA (fun a => map (f a)         muB)
  = bind muB (fun b => map (fun a => f a b) muA).
Proof. 
apply Valeq_compat. unfold Valeq. intros P.
simpl.
eapply fubini_no_funext.
intros a. rewrite <- int_indicator. reflexivity. 
intros b. rewrite <- int_indicator. reflexivity. 
simpl. reflexivity. 
Qed.

(** If we believe the statement of Fubini's theorem above, then
    we have a bind operation on random samplers! *)
Definition sbind {R A B : Type} (random : Valuation R)
  (mu : Valuation A) (smu : Sampler random mu) 
  (f : A -> Valuation B) (sf : forall a, Sampler random (f a))
  : Sampler random (bind mu f).
Proof. 
pose (func := fun p : (R * A) => sf (snd p) (fst p)).
refine (
  {| sample := fun r => func (smu r) |}
).
rewrite map_compose.
rewrite (sample_ind _ _ smu).
apply Valeq_compat. unfold Valeq. intros. simpl.

erewrite fubini_no_funext.
Focus 2. intros. rewrite <- int_indicator. reflexivity.
Focus 3. intros. simpl. reflexivity.
Focus 2. intros. reflexivity.

pose (func2 := fun p => (f (snd p)) (fun b => P (fst p, b))).
assert (
 (fun x : R =>
      integral (fun x0 : A => (f x0) (fun x1 : B => P (x, x1))) mu)
 = 
 (fun x : R =>
      integral (fun x0 : A => func2 (x, x0)) mu)
).
apply functional_extensionality. intros r.
reflexivity. rewrite H. clear H. 
rewrite fubini.
apply int_pointwise_eq. unfold pointwise. intros a.
apply LPReq_compat_backwards.
pose proof (sample_ind _ _ (sf a)).
unfold func2. simpl.
assert (forall P, (map (sf a) random) P = (product random (f a)) P).
intros. rewrite H. reflexivity.
simpl in H0.
rewrite int_indicator. apply H0.
Defined.

Lemma int_indicator_funext {A : Type}
  { P : A -> Prop } {mu : Valuation A}
  { f : A -> LPReal }
  : (forall a, LPRindicator (P a) = f a)
  -> integral f mu = mu P.
Proof.
intros.
replace f with (fun a => LPRindicator (P a)) by
  (apply functional_extensionality; intros; apply H).
apply int_indicator.
Qed.

Lemma union_bound2 {A : Type} {mu : Valuation A}
  (P Q : A -> Prop)
  : mu (fun z => P z \/ Q z) <= mu P + mu Q.
Proof.
rewrite modular. eapply LPRle_trans.
Focus 2. eapply LPRplus_le_compat.
apply LPRzero_min. apply LPRle_refl.
rewrite (SRadd_0_l LPRsrt). 
apply LPRle_refl.
Qed.

Lemma union_bound {A : Type} {mu : Valuation A}
  (xs : list (A -> Prop))
  : mu (List.fold_right (fun P Q z => P z \/ Q z) (K False) xs) <=
    List.fold_right LPRplus 0 (List.map (val mu) xs).
Proof.
induction xs; simpl.
- rewrite strict. apply LPRle_refl.
- eapply LPRle_trans. Focus 2. 
  eapply LPRplus_le_compat.
  Focus 2. apply IHxs. apply LPRle_refl.
  apply union_bound2.
Qed.

Lemma streamTl {A : Type} (mu : Valuation A)
  (nonempty : A)
  (mu1 : mu (K True) = 1)
  : map (@Streams.tl A) (inf_product mu nonempty mu1) = 
    inf_product mu nonempty mu1.
Proof.
apply Valeq_compat. unfold Valeq. intros P.
simpl. apply LPReq_compat. 
split; apply LPRsup_le; intros n;
apply LPRsup_ge2. 
- exists (S n). simpl.
  erewrite fubini_no_funext.
    Focus 2. intros. rewrite <- int_indicator. reflexivity. 
    Focus 2. intros. reflexivity.
    Focus 2. intros. simpl. reflexivity.
  erewrite int_pointwise_eq.
    Focus 2. unfold pointwise; intros.
    apply LPReq_compat_backwards.
    rewrite int_indicator. reflexivity.
  (*
  apply monotonic.
  apply int_monotonic. unfold pointwise. 
  intros xs. rewrite int_indicator.
*)
admit.
- exists (S n). simpl. admit.
Qed.

Definition streamSampler {A : Type} (mu : Valuation A)
  (nonempty : A) (mu1 : mu (K True) = 1)
  : Sampler (inf_product mu nonempty mu1) mu.
Proof. refine (
  {| sample := fun r => match r with
     | Streams.Cons a r' => (r', a)
     end
  |}
). apply Valeq_compat. unfold Valeq. intros P.
Abort.

(* Random samplers which may diverge. *)
Record PSampler {R A : Type} (propext : forall P Q, (P <-> Q) -> P = Q)
  (random : Valuation R) (mu : Valuation A)
  : Type :=
  { psample     :> R -> Partial (R * A)
  ; psample_ind :  partialValuation propext (map psample random) = product random mu
  }.

Lemma partialValNow {A : Type} propext (mu : Valuation A)
  : partialValuation propext (map Now mu) = mu.
Proof.
apply Valeq_compat. unfold Valeq; intros.
simpl.
replace ((fun x : A => partialize P (Now x))) with P.
reflexivity.
apply functional_extensionality. simpl. intros x.
apply propext. split; intros. unfold partialize.
exists 0%nat. simpl. assumption.
unfold partialize in H. destruct H.
rewrite partial_now in H. assumption.
Qed.

(* Any total sampler can be considered as a partial sampler. *)
Definition partializeSampler {R A : Type}
  propext {random : Valuation R} {mu : Valuation A}
  (f : Sampler random mu)
  : PSampler propext random mu.
Proof.
refine (
  {| psample := fun r => Now (f r) |}
).
rewrite map_compose. rewrite (sample_ind _ _ f).
apply partialValNow.
Defined.

Lemma partialLoop {A : Type} : forall n, runPartial loop n = (@None A).
intros. induction n. simpl. reflexivity.
simpl. apply IHn.
Qed.

Definition zeroPSampler {R A : Type} propext
  {random : Valuation R}
  : PSampler propext random (@zeroVal A).
Proof. refine (
  {| psample := fun r => loop |}
).
apply Valeq_compat. unfold Valeq. intros P.
simpl. rewrite <- (LPRind_false False) by auto.
rewrite int_indicator. 
replace (partialize P loop) with False. reflexivity.
apply propext. split; intros. contradiction.
unfold partialize in H. destruct H. rewrite partialLoop in H.
assumption.
Defined.

(** The notion of a measure being dominated by another will be important
    for defining PDFs. The is also sometimes called absolute continuity. *)
Definition DominatedBy {A : Type} (mu nu : Valuation A) :=
  forall (P : A -> Prop), nu P = 0 -> nu P = 0.

Lemma DominatedBy_refl {A : Type} (mu : Valuation A)
  : DominatedBy mu mu.
Proof. unfold DominatedBy. auto. Qed.

Lemma DominatedBy_trans {A : Type} (u v w : Valuation A)
  : DominatedBy u v -> DominatedBy v w -> DominatedBy u w.
Proof. unfold DominatedBy. auto. Qed.

(** The function [pdf] represents a PDF of [mu] given with respect to
    [lambda]. In general, we might thing of [mu] as something funny, whereas
    [lambda] might be something nice and easy to integrate over, such as
    Lebesgue measure on the interval. *)
Record PDF {A B : Type} (lambda : Valuation A) (mu : Valuation B) : Type :=
  { pdf :> A -> LPReal
  ; pdf_integrates : forall (P : B -> Prop),
    integral pdf lambda = mu P
  }.

(**  The Radon-Nikodym theorem looks something like this below... *)
Definition Radon_Nikodym_statement :=
  forall (A : Type) (mu lambda : Valuation A)
  , DominatedBy mu lambda -> PDF lambda mu.

(** If we have PDFs for two measures, we naturally get a PDF for their
    product measure. *)
Definition product_PDF {A A' B B': Type} 
  {lambda1 : Valuation A} {lambda2 : Valuation B}
  {mu : Valuation A'} {nu : Valuation B'}
  (pdfmu : PDF lambda1 mu) (pdfnu : PDF lambda2 nu)
  : PDF (product lambda1 lambda2) (product mu nu).
Proof. refine (
  {| pdf := fun p : A * B => let (x, y) := p in pdfmu x * pdfnu y |}
).
Abort.

Lemma unit_prob {A : Type} {x : A} : unit x (K True) = 1.
Proof. apply LPRind_true. unfold K. constructor. Qed.

Definition bernoulli (p : Qnn) (ple1 : (p <= 1)%Qnn)
  : Valuation bool :=
 pchoice (LPRQnn p) (LPRQnn (Qnnminus 1%Qnn p ple1))
  (unit true) (unit false).

Lemma bernoulli_prob {p : Qnn} {ple1 : (p <= 1)%Qnn}
  : bernoulli p ple1 (K True) = 1.
Proof. apply pchoice_prob; try apply unit_prob.
rewrite LPRQnn_plus.
apply LPRQnn_eq. apply Qnnminus_plus.
Qed.

Lemma bind_prob {A B : Type} {mu : Valuation A}
  {f : A -> Valuation B}
  : mu (K True) = 1
  -> (forall a, (f a) (K True) = 1)
  -> bind mu f (K True) = 1.
Proof.
intros Hmu Hf. simpl.
rewrite <- Hmu. 
rewrite <- int_indicator.
apply int_pointwise_eq. unfold pointwise.
unfold K.
rewrite LPRind_true by trivial.
intros a.
apply LPReq_compat_backwards.
apply Hf.
Qed.

Fixpoint binomial (p : Qnn) (ple1 : (p <= 1)%Qnn)
  (n : nat)
  : Valuation nat := match n with
  | 0 => unit 0%nat
  | S n' => bind (bernoulli p ple1) (fun b => 
   let inc := if b then S else fun x => x in
  (map inc (binomial p ple1 n')))
  end. 

Lemma binomial_prob (p : Qnn) (ple1 : (p <= 1)%Qnn)
  (n : nat) : binomial p ple1 n (K True) = 1.
Proof.
induction n; simpl.
- unfold K. apply LPRind_true. constructor.
- unfold K in *. rewrite IHn. 
rewrite <- (LPRind_true True) by trivial. 
rewrite int_indicator.
rewrite LPRind_true by trivial. apply bernoulli_prob.
Qed.

Require Import Alea.BinCoeff.

Lemma val_iff {A : Type} {mu : Valuation A}
  {P Q : A -> Prop} : (forall a, P a <-> Q a) -> mu P = mu Q.
Proof.
intros. apply LPReq_compat. split; apply monotonic; apply H.
Qed.

Definition restrict {A : Type} (mu : Valuation A)
  (P : A -> Prop) : Valuation A.
Proof.
refine (
{| val := fun Q => mu (fun x => P x /\ Q x) |}
).
- simpl. erewrite val_iff. apply strict. unfold K.
  intros. intuition. 
- intros. apply monotonic. intros. destruct H0.
  split. assumption. apply H. assumption.
- intros. replace 
  (mu (fun x : A => P x /\ U x /\ V x)) with
  (mu (fun x => (P x /\ U x) /\ (P x /\ V x))). replace 
  (mu (fun x : A => P x /\ (U x \/ V x))) with
  (mu (fun x => (P x /\ U x) \/ (P x /\ V x))).
  apply modular. apply val_iff. intros. intuition.
  apply val_iff. intros. intuition.
Defined.

Lemma restrict_monotonic {A : Type} {mu : Valuation A}
  { P Q : A -> Prop} : (forall a, P a -> Q a) 
  -> (restrict mu P <= restrict mu Q)%Val.
Proof.
intros. unfold Valle. intros p. simpl.
apply monotonic. intros; intuition.
Qed.

Lemma restrict_true {A : Type} {mu : Valuation A}
  { P : A -> Prop } : (forall a, P a)
  -> restrict mu P = mu.
Proof.
intros. apply Valeq_compat. unfold Valeq.
intros Q. simpl. apply val_iff. intros. intuition.
Qed.

Lemma restrict_false {A : Type} {mu : Valuation A}
  {P : A -> Prop} : A -> (forall a, ~ P a)
  -> restrict mu P = zeroVal.
Proof. intros. apply Valeq_compat. unfold Valeq. 
intros Q. simpl. erewrite val_iff. apply strict.
intros; unfold K; intuition. apply (H a). assumption.
Qed.

Lemma LPRmax_le {x y x' y' : LPReal} 
  : x <= x' -> y <= y' -> LPRmax x y <= LPRmax x' y'.
Proof.
intros. unfold LPRle. intros q Hmax. simpl in *.
destruct Hmax; [left | right].
- apply H. assumption.
- apply H0. assumption.
Qed.

Lemma simple_int_monotonic_val {A : Type} {f : Simple A}
  {mu mu' : Valuation A}
  : (mu <= mu')%Val -> SimpleIntegral mu f <= SimpleIntegral mu' f.
Proof. intros. induction f; simpl.
- apply LPRmult_le_compat. apply LPRle_refl. apply H.
- simpl. apply LPRmax_le; assumption.
Qed.

Lemma int_monotonic_val {A : Type} {f : A -> LPReal}
  {mu mu' : Valuation A}
  : (mu <= mu')%Val -> integral f mu <= integral f mu'.
Proof. intros.
unfold integral. apply LPRsup_monotonic.
intros. destruct a. simpl. apply simple_int_monotonic_val.
assumption.
Qed.

Lemma LPRmax_plus {x x' y y' : LPReal}
  : LPRmax (x + x') (y + y') <= LPRmax x y + LPRmax x' y'.
Proof.
apply LPRmax_le_and; apply LPRplus_le_compat; apply LPRmax_le_or;
  (left; apply LPRle_refl) || (right; apply LPRle_refl).
Qed.

Lemma simple_int_sub_adds_val {A : Type} {f : Simple A}
  {mu mu' : Valuation A}
  : SimpleIntegral (mu + mu')%Val f 
  <= SimpleIntegral mu f + SimpleIntegral mu' f.
Proof.
induction f; simpl.
- assert (forall x y, x = y -> x <= y). intros; subst; apply LPRle_refl. 
  apply H. ring.
- simpl in *. eapply LPRle_trans. eapply LPRmax_le; eassumption.
  apply LPRmax_plus.
Qed.

Lemma int_adds_val {A : Type} {f : A -> LPReal}
  {mu mu' : Valuation A}
  : integral f (mu + mu')%Val = integral f mu + integral f mu'.
Proof.
Admitted.

Lemma LPRmax_scales {c x y : LPReal} 
  : LPRmax (c * x) (c * y) = c * LPRmax x y.
Proof. 
apply LPReq_compat. split.
- apply LPRmax_le_and; (apply LPRmult_le_compat;
  [ apply LPRle_refl 
  | apply LPRmax_le_or; auto using LPRle_refl]).
- unfold LPRle; simpl; intros. 
  destruct H as [a [b [ca [xyb qab]]]].
  destruct xyb; [left | right];
  exists a; exists b; auto.
Qed.

Lemma LPRsup_scales {A : Type} {f : A -> LPReal}
  {c : LPReal}
  : c * LPRsup f = LPRsup (fun x => c * f x).
Proof.
apply LPReq_compat; split.
- unfold LPRle; simpl; intros.
  destruct H as [a [b [ca [sup qab]]]].
  destruct sup. exists x. exists a. exists b. intuition.
- apply LPRsup_le. intros. apply LPRmult_le_compat.
  apply LPRle_refl. apply LPRsup_ge.
Qed.

Lemma simple_int_scales_val {A : Type} {f : Simple A}
  {mu : Valuation A} {c : LPReal}
  : SimpleIntegral (c * mu)%Val f = c * SimpleIntegral mu f.
Proof. induction f; simpl in *.
- ring. 
- rewrite IHf1. rewrite IHf2. apply LPRmax_scales.
Qed.

Lemma int_scales_val {A : Type} {f : A -> LPReal}
  {mu : Valuation A} {c : LPReal}
  : integral f (c * mu)%Val = c * integral f mu.
Proof.
unfold integral. symmetry. 
replace (fun pr : {s : Simple A | pointwise LPRle (SimpleEval s) f} =>
      SimpleIntegral (c * mu)%Val (proj1_sig pr)) with 
  (fun pr : {s : Simple A | pointwise LPRle (SimpleEval s) f} =>
      c * SimpleIntegral mu (proj1_sig pr)).
apply LPRsup_scales.
apply functional_extensionality. intros. 
symmetry. apply simple_int_scales_val.
Qed.

Definition val_destruct {A : Type} (mu : Valuation A)
  (P : A -> Prop) : Valuation A :=
  (restrict mu P + restrict mu (fun a => ~ P a))%Val.

Lemma val_destruct_dec {A : Type} {mu : Valuation A}
  {P : A -> Prop} : (forall a, {P a} + {~ P a})
  -> val_destruct mu P = mu.
Proof.
intros dec_P.
apply Valeq_compat.
unfold Valeq. intros Q. simpl. apply LPReq_compat. split.
- rewrite modular. replace (mu (fun z : A => (P z /\ Q z) /\ ~ P z /\ Q z))
  with 0. rewrite (SRadd_0_l LPRsrt). apply monotonic.
  intuition.
  erewrite val_iff. symmetry. apply strict. unfold K; intros; intuition.
- eapply LPRle_trans. 2:apply union_bound2. simpl.
  apply monotonic. intros. 
  destruct (dec_P z); [left | right]; intuition.
Qed.

Lemma Qnnnat_plus {x y : nat} : (Qnnnat (x + y) = Qnnnat x + Qnnnat y)%Qnn.
Proof.
induction x.
- simpl; ring.
- simpl. rewrite IHx. ring.
Qed.

Lemma minus_Succ {k n : nat} : (S k <= n -> S (n - S k) = n - k)%nat.
Proof.
intros. rewrite Minus.minus_Sn_m. simpl. reflexivity. assumption.
Qed.

Lemma binomial_bounded {p : Qnn} {ple1 : (p <= 1)%Qnn}
  {n : nat} (k : nat) : (n < k)%nat -> (binomial p ple1 n) (eq k) = 0.
Proof.
intros. generalize dependent k. induction n; intros.
- simpl. rewrite LPRind_false. reflexivity.
  unfold not; intros. subst. 
  apply Lt.lt_0_neq in H. apply H. reflexivity.
- simpl. unfold bernoulli, pchoice. rewrite int_adds_val.
  repeat rewrite int_scales_val. repeat rewrite int_dirac.
  rewrite IHn.
  assert ((binomial p ple1 n) (fun x : nat => k = S x) = 0).
  pose proof (Lt.S_pred _ _ H).
  rewrite (val_iff (Q:= eq (pred k))).
  apply IHn. unfold lt in *. rewrite H0 in H. apply le_S_n.
  assumption. intros. split; intros. rewrite H1. simpl. reflexivity.
  rewrite H0. congruence. rewrite H0. ring.
  apply Lt.lt_S_n. apply Lt.lt_S. assumption.
Qed.
  
  

Lemma binomial_pdf (p : Qnn) (ple1 : (p <= 1)%Qnn)
  (n : nat) (k : nat) :
  (k <= n)%nat ->
    (binomial p ple1 n) (eq k)
  = LPRQnn (Qnnnat (comb k n)
    * p ^ k * Qnnminus 1 p ple1 ^ (n - k))%Qnn.
Proof. generalize dependent k.
induction n.
- intros. apply Le.le_n_0_eq in H. subst. simpl.
  rewrite LPRind_true by reflexivity.
  apply LPRQnn_eq. ring.
- intros k. induction k; intros.
  + simpl. specialize (IHn 0%nat (Le.le_0_n _)).
    rewrite comb_0_n in IHn. simpl in IHn.
    rewrite <- Minus.minus_n_O in IHn.
    replace 
     (((1 + 0) * 1 * (Qnnminus 1 p ple1 * Qnnminus 1 p ple1 ^ n))%Qnn)
     with
     (Qnnminus 1 p ple1 * ((1 + 0) * 1 * (Qnnminus 1 p ple1 ^ n)))%Qnn
     by ring.
    rewrite <- LPRQnn_mult. rewrite <- IHn. unfold bernoulli.
    unfold pchoice.
    rewrite int_adds_val. do 2 rewrite int_scales_val.
    simpl. do 2 rewrite int_dirac.
    replace ((binomial p ple1 n) (fun x : nat => 0%nat = S x))
    with 0. replace (fun x : nat => 0%nat = x) with (eq 0%nat)
     by (extensionality a; reflexivity). 
    ring. erewrite val_iff. symmetry. apply strict.
    unfold K. intuition.
  + simpl. unfold bernoulli. unfold pchoice.
    rewrite int_adds_val. do 2 rewrite int_scales_val. 
    simpl. do 2 rewrite int_dirac. 
    rewrite (val_iff (Q := eq k)).
    specialize (IHk (Le.le_Sn_le _ _ H)).
    pose proof (IHn k (le_S_n _ _ H)).
    rewrite H0.
    destruct (Compare_dec.le_dec (S k) n).
    * specialize (IHn (S k) l). 
      replace (fun x : nat => S k = x) with (eq (S k))
       by (extensionality a; reflexivity).
      rewrite IHn. simpl. repeat rewrite LPRQnn_mult.
      rewrite LPRQnn_plus. apply LPRQnn_eq. 
      pose proof (@Qnnminus_plus p 1%Qnn ple1).
      rewrite Qnnnat_plus.
      replace (Qnnminus 1 p ple1 ^ (n - k))%Qnn
      with    (Qnnminus 1 p ple1 * Qnnminus 1 p ple1 ^ (n - S k))%Qnn.
      ring.
      rewrite <- (@minus_Succ k n) by assumption.
      simpl. reflexivity.
    * assert (k = n). apply Le.le_antisym. apply le_S_n. assumption.
      fold (lt k n) in n0. destruct (Lt.le_or_lt n k). assumption.
      contradiction. subst. repeat rewrite comb_n_n.
      repeat rewrite comb_Sn_n.
      replace ((binomial p ple1 n) (fun x : nat => S n = x)) with (LPRQnn 0%Qnn).
      repeat rewrite LPRQnn_mult. repeat rewrite LPRQnn_plus.
      apply LPRQnn_eq. simpl. ring.
      symmetry. apply binomial_bounded. apply Lt.lt_n_Sn.
    * intros. split; intros; congruence.
Qed.
      
