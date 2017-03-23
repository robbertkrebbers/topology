Require Import 
  Coq.Program.Basics
  FormTopC.FormTop
  FormTopC.Cont
  FormTopC.FormalSpace
  Algebra.OrderC
  Algebra.SetsC
  CMorphisms
  Prob.StdLib.

Set Universe Polymorphism.
Set Asymmetric Patterns.

Local Open Scope Subset.
Local Open Scope FT.

(** Information bases, which are the predicative versions of
    Scott domains. Perhaps, see Definition 1.9 of [2].
    Though my formulation is a little different; I build off
    of a pre-existing notion of a meet semi-lattice.

    Also, I directly show that this formal topology is
    inductively generated by generating it with an axiom set. *)
Module InfoBase. 
Section InfoBase.

Set Printing Universes.
Universes A P AP.
Variable (S : FormTop.PreOrder@{A P}).

Context {PO : PreO.t@{A P} (le S)}.

(** The axiom set essentially says that if [s <= t], then
    [s] is covered by the singleton set [{t}]. *)
Inductive Ix@{} {s : S} : Type@{P} := .

Arguments Ix : clear implicits.

Definition C@{} (s : S) (s' : Ix s) : Subset@{A P} S := match s' with
  end.

Definition IBInd@{} : PreISpace.t@{A P P} :=
  {| PreISpace.S := S
   ; PreISpace.Ix := Ix
   ; PreISpace.C := C
  |}.

Definition Cov (s : S) (U : Subset@{A P} S) : Type@{P} :=
  In (⇓ U) s.

Definition IB@{} : PreSpace.t@{A P P} :=
  {| PreSpace.S := S
   ; PreSpace.Cov := Cov |}.

(** This axiom set is localized. *)
Local Instance loc@{} : FormTop.localized IBInd.
Proof.
unfold FormTop.localized. intros. induction i.
Qed.

Theorem CovEquiv : PreSpace.Cov IB ==== GCovL IBInd.
Proof.
intros a U. simpl. unfold Cov. split; intros.
- destruct X as [t Ut st].
  apply FormTop.glle_left with t. assumption.
  apply FormTop.glrefl. assumption. 
- induction X. 
  + exists a. assumption. reflexivity.
  + destruct IHX as [t Ut bt].
    exists t. assumption. etransitivity; eassumption.
  + destruct i.
Qed.

(** The proof that [Cov] is a valid formal topology. *)
Local Instance isCovG : FormTop.t IBInd := 
  FormTop.GCovL_formtop _.

(** Should prove this via homeomorphism with IBInd. *)
Local Instance isCov@{} : FormTop.t IB.
Proof.
Admitted.

Local Instance Pos : FormTop.gtPos IBInd.
Proof.
apply FormTop.gall_Pos.
intros. destruct i.
Qed.

Definition InfoBase@{} : IGt@{A P P AP} :=
  {| IGS := IBInd |}.

End InfoBase.
End InfoBase.

Arguments InfoBase.Ix : clear implicits.

Module InfoBaseCont.
Section InfoBaseCont.

Generalizable All Variables.

Context {S : PreSpace.t} {POS : PreO.t (le (PreSpace.S S))}.
Context {T : FormTop.PreOrder} {POT : PreO.t (le T)}.

Record ptNM {F : Subset T} : Type :=
  { ptNM_local : forall {a b}, F a -> F b -> 
     Inhabited (F ∩ (eq a ↓ eq b))
  ; ptNM_le_right : forall a b, a <=[T] b -> F a -> F b
  ; ptNM_here : Inhabited F
  }.

Arguments ptNM : clear implicits.

Instance ptNM_proper : Proper ((eq ==> iffT) ==> iffT) ptNM.
Proof.
Admitted.


(** I have no idea whether this is in fact
    a good definition *)
Record tNM {F_ : Cont.map S (InfoBase.IB T)} :=
  { NMle_left : forall a b c, a <=[PreSpace.S S] b -> F_ c b -> F_ c a
  ; NMle_right :  forall a b c, F_ b a -> b <=[T] c -> F_ c a
  ; NMlocal : forall {a b c}, F_ b a -> F_ c a -> 
     Inhabited ((fun t => F_ t a) ∩ (eq b ↓ eq c))
  ; NMhere : forall s : S, In (union (fun _ => True) F_) s
  }.

Arguments tNM : clear implicits.

Hypothesis FTS : FormTop.t S.

Theorem contNM : forall (F : Cont.map S (InfoBase.IB T)),
  tNM F
  -> Cont.t S (InfoBase.IB T) F.
Proof.
intros. constructor; intros.
- unfold InfoBase.Cov. apply FormTop.refl.
  apply (NMhere X).
- eapply (NMle_left X); eassumption. 
- unfold InfoBase.Cov. apply FormTop.refl. 
  pose proof (NMlocal X X0 X1).
  destruct X2. destruct i.
  econstructor; eassumption.
- simpl in *. unfold InfoBase.Cov in *. 
  destruct X1 as [t0 Vt0 bt0].
  apply FormTop.refl. exists t0. assumption.
  apply (NMle_right X) with b; assumption.
Qed.

End InfoBaseCont.

Arguments tNM : clear implicits.
Arguments ptNM : clear implicits.

(*
Section InfoBaseML.

Context {S : PreSpace.t} {POS : PreO.t (le S)}.
Context {T} `{MeetLat.t T}.

Record pt {F : Subset T} : Type :=
  { pt_local : forall {a b}, F a -> F b -> F (MeetLat.min a b)
  ; pt_le_right : forall a b, MeetLat.le a b -> F a -> F b
  ; pt_here : Inhabited F
  }.

Arguments pt : clear implicits.

Instance pt_proper : Proper ((eq ==> iffT) ==> iffT) pt.
Proof.
Admitted.

Lemma down_min : forall a b,
 In (FormTop.down MeetLat.le a b) (MeetLat.min a b).
Proof.
intros. constructor; apply MeetLat.min_ok.
Qed.

Theorem pt_ptNM : forall F, pt F -> ptNM MeetLat.le F.
Proof.
intros F H0. destruct H0. constructor; eauto.
intros. constructor 1 with (MeetLat.min a b).
econstructor. unfold In. eauto. apply down_min.
Qed.

(** I have no idea whether this is in fact
    a good definition *)
Record t {F_ : Cont.map S T} :=
  { le_left : forall a b c, leS a b -> F_ c b -> F_ c a
  ; le_right :  forall a b c, F_ b a -> MeetLat.le b c -> F_ c a
  ; local : forall {a b c}, F_ b a -> F_ c a -> 
     F_ (MeetLat.min b c) a
  ; here : forall s : S, In (union (fun _ => True) F_) s
  }.

Arguments t : clear implicits.

Variable CovS : S -> Subset S -> Type.
Hypothesis FTS : FormTop.t leS CovS.
Let CovT : T -> Subset T -> Type := @InfoBase.Cov _ MeetLat.le.

Theorem cont : forall (F : Cont.map S T),
  t F -> Cont.t leS MeetLat.le CovS CovT F.
Proof.
intros. apply contNM. assumption.
destruct X. constructor; eauto.
intros. specialize (local0 _ _ _ X X0).
constructor 1 with (MeetLat.min b c).
constructor; eauto. apply down_min.
Qed.

Definition above_pt (x : T) : pt (MeetLat.le x).
Proof.
constructor; intros.
- apply MeetLat.min_ok; assumption.
- etransitivity; eassumption.
- econstructor. unfold In. reflexivity.
Qed.

Definition lift_op (f : S -> T) (y : T) (x : S) : Type :=
  MeetLat.le (f x) y.

Definition lift_monotone (f : S -> T)
  (fmono : forall x y, leS x y -> MeetLat.le (f x) (f y))
  : t (lift_op f).
Proof.
constructor; unfold lift_op; intros.
- etransitivity. apply fmono. eassumption. assumption. 
- etransitivity; eassumption.
- apply MeetLat.min_ok; assumption.
- econstructor. unfold In. constructor. reflexivity.
Qed.

End InfoBaseML.

Arguments t {_} leS {_ _} F_.
Arguments pt {_} {_} F.
Arguments lift_op {_ _ _} f y x.

Section Product.

Context {S} `{MeetLat.t S}.
Context {T} `{MeetLat.t T}.
Context {U} `{MeetLat.t U}.

Definition lift_binop (f : S -> T -> U)
  (result : U) (args : S * T) : Type :=
  let (l, r) := args in MeetLat.le (f l r) result.

Existing Instances MeetLat.product_ops MeetLat.product.

Theorem lift_binop_monotone : forall (f : S -> T -> U)
  (fmono : forall x x' y y', MeetLat.le x x' -> MeetLat.le y y' 
     -> MeetLat.le (f x y) (f x' y'))
  , t MeetLat.le (lift_binop f).
Proof.
intros. unfold lift_binop. constructor; intros.
- destruct a, b. simpl in *. unfold prod_op in *.
  destruct X. rewrite <- X0. apply fmono; assumption.
- destruct a. rewrite <- X0.  assumption.
- destruct a. apply MeetLat.min_ok; assumption.
- destruct s. econstructor. constructor. 
  reflexivity.
Qed.

End Product.


Section Compose.

Context {S} {leS : crelation S} {SOps} {MLS : MeetLat.t S SOps}.

Instance OneOps : MeetLat.Ops True := MeetLat.one_ops.

Theorem to_pt : forall (F : Cont.map True S), t MeetLat.le F ->
  pt (fun s => F s I).
Proof.
intros F H. constructor; intros.
- apply (local H); assumption. 
- eapply (le_right H); eassumption. 
- pose proof (here H I) as X. destruct X.
  econstructor; eauto.
Qed.

Theorem from_pt : forall (F : Subset S), pt F -> t MeetLat.le (fun t' _ => F t').
Proof.
intros F H. constructor; intros.
- assumption.
- eapply (pt_le_right H); eassumption.
- apply (pt_local H); assumption.
- pose proof (pt_here H) as X. destruct X. 
  repeat (econstructor || eauto).
Qed.

Context {T TOps} {MLT : MeetLat.t T TOps}.
Context {U UOps} {MLU : MeetLat.t U UOps}.

Theorem t_compose (F : Cont.map S T) (G : Cont.map T U)
  : t MeetLat.le F -> t MeetLat.le G
  -> t MeetLat.le (compose G F).
Proof.
intros HF HG.
constructor; unfold compose; intros.
- destruct X0 as (t & Fbt & Gtc).
  exists t. split. 
  + assumption. 
  + eapply (le_left HF); eassumption.
- destruct X as (t & Fat & Gtb).
  exists t. split. eapply (le_right HG); eassumption.
  assumption.
- destruct X as (t & Fat & Gtb).
  destruct X0 as (t' & Fat' & Gt'c).
  exists (MeetLat.min t t'). split. 
  + apply (local HG); eapply (le_left HG). 
    apply MeetLat.min_l. assumption. 
    apply MeetLat.min_r. assumption. 
  + apply (local HF); assumption.
- destruct (here HF s). destruct (here HG a).
  exists a0. constructor. exists a. auto.
Qed.

End Compose.

Section EvalPt.

Context {S SOps} {MLS : MeetLat.t S SOps}.
Context {T TOps} {MLT : MeetLat.t T TOps}.

Definition eval (F : Cont.map S T) (x : Subset S) (t : T) : Type :=
  Inhabited (x ∩ F t).

Theorem eval_pt (F : Cont.map S T) (x : Subset S)
  : pt x -> t MeetLat.le F -> pt (eval F x).
Proof.
intros Hx HF.
pose proof (t_compose (fun t _ => x t) F (from_pt _ Hx) HF) as H.
apply to_pt in H. 
eapply pt_proper. 2: eassumption. simpl_crelation.
unfold eval. split; intros.
- destruct X. destruct i. econstructor; eauto.
- destruct X. destruct p. repeat (econstructor || eauto).
Qed.

End EvalPt.
*)

End InfoBaseCont.

(*
Arguments InfoBaseCont.t {S} leS {T} {TOps} F : rename, clear implicits.
*)

Module One.
Section One.

Definition OnePO : FormTop.PreOrder :=
  {| PO_car := True
   ; le := fun _ _ => True
  |}.

Definition One : PreISpace.t := InfoBase.IBInd OnePO.

Section One_intro.

Context {S : PreSpace.t} {FTS : FormTop.t S}.

Definition One_intro : Cont.map S One :=
   fun (_ : True) (s : S) => True.

Theorem One_intro_cont : 
  Cont.t S One One_intro.
Proof.
constructor; unfold One_intro; intros; simpl; try auto.
- apply FormTop.refl. unfold In; simpl. constructor 1 with I.
  unfold In; simpl; constructor. constructor.
- apply FormTop.refl. unfold In; simpl. 
  exists I. destruct b, c. unfold FormTop.down, In; auto.
  split; eexists; unfold In; eauto. auto.
- apply FormTop.refl. constructor 1 with I.
  induction X. destruct a0. assumption.
  assumption.  destruct i. auto.
Qed.

End One_intro.

Context {S : PreSpace.t} {POS : PreO.t (le (PreSpace.S S))}.

Definition Point (f : Subset S) := Cont.t One S (fun t _ => f t).

End One.
End One.

Module Sierpinski.

Definition SierpPO : FormTop.PreOrder :=
  {| PO_car := bool
   ; le := Bool.leb |}.

Definition Sierp := InfoBase.IBInd SierpPO.

Definition ProdPO (A B : FormTop.PreOrder) : FormTop.PreOrder :=
  {| PO_car := A * B
  ; le := prod_op (le A) (le B) |}.

(*
Definition sand : Cont.map (InfoBase.IBInd (ProdPO SierpPO SierpPO))
  Sierp :=
  InfoBaseCont.lift_binop andb.

Existing Instances MeetLat.product MeetLat.product_ops.

Theorem sand_cont : InfoBaseCont.t MeetLat.le sand.
Proof.
apply InfoBaseCont.lift_binop_monotone.
simpl. intros. destruct x, x', y, y'; auto.
Qed.

Definition sor : Cont.map (bool * bool) bool :=
  InfoBaseCont.lift_binop orb.

Theorem sor_cont : InfoBaseCont.t MeetLat.le sor.
Proof.
apply InfoBaseCont.lift_binop_monotone.
simpl. intros. destruct x, x', y, y'; auto; congruence.
Qed.

Definition const_cont (b : bool) : InfoBaseCont.pt (MeetLat.le (negb b)).
Proof.
apply InfoBaseCont.above_pt.
Qed.
*)

End Sierpinski.

