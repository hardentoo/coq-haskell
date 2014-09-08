(* This file formalizes the proofs from Duncan Coutts' thesis:

   "Stream Fusion: Practical shortcut fusion for coinductive sequence types".

   http://community.haskell.org/~duncan/thesis.pdf
*)

Require Export Coq.Unicode.Utf8.
Require Import Coq.Init.Datatypes.
Require Import Coq.Program.Tactics.
Require Import FunctionalExtensionality.

Require Import Endo.
Require Import Iso.

Close Scope nat_scope.

(* Section 2.2.3 *)

Definition NatF (a : Type) := unit + a.

(* This does not work in Coq, but of the strict positivity requirement. *)
(* Inductive Fix (F : Type -> Type) := outF : F (Fix F) -> Fix F. *)

(* This definition works fine, however, and is equivalent. *)
Definition μ (F : Type -> Type) := ∀ a, (F a → a) → a.

Definition Nat := μ NatF.

(* Definition zero : Nat := λ a (X : NatF a   → a), X (inl tt). *)
(* Definition one  : Nat := λ a (X : unit + a → a), X (inr (X (inl tt))). *)

Program Instance sum_distributive : ∀ a b c, ((a + b) → c) ≅ ((a → c) * (b → c)).
Solve All Obligations using auto.
Obligation 2. destruct X0; auto. Defined.
Obligation 3.
  compute.
  extensionality x.
  extensionality n.
  destruct n; auto.
Qed.
Obligation 4.
  compute.
  extensionality x.
  destruct x. auto.
Qed.

Program Instance unit_impl : ∀ a, (unit → a) ≅ a.
Solve All Obligations using auto.
Obligation 1. apply X. constructor. Defined.
Obligation 3.
  compute.
  extensionality H.
  extensionality tt.
  destruct tt. reflexivity.
Qed.

Definition ChurchNat := ∀ a, a → (a → a) → a.

Program Instance nat_is_Church : Nat ≅ ChurchNat.
Obligation 1.
  compute in *. intros.
  apply X. intros.
  induction X2 as [| H].
    apply X0.                   (* Z case *)
  apply X1. apply H.            (* S case *)
Defined.
Obligation 2.
  compute in *. intros.
  apply X; intros; apply X0.
    left. constructor.          (* Z case *)
  right. apply X1.              (* S case *)
Defined.
Obligation 3.
  compute.
  extensionality H.
  extensionality a.
  extensionality X0.
  f_equal.
  extensionality X2.
  destruct X2.
    destruct u. reflexivity.
  reflexivity.
Qed.

Section F.
  Variable F : Type → Type.
  Context `{Functor F}.

(* Definition 2.2.1 *)
Definition fold : ∀ a, (F a → a) → μ F → a :=
  fun a => fun k => fun x => x a k.

(* Definition 2.2.2 *)
Definition build : (∀ a, (F a → a) → a) → μ F :=
  fun g => fun b => fun k => g b k.

Inductive nu : Type := unNu : ∀ a, a → (a → F a) → nu.

(* Definition 2.2.3 *)
Definition unfold : ∀ a, (a → F a) → a → nu :=
  fun a => fun k => fun s => unNu a s k.

(* Definition 2.2.4 *)
Definition unbuild : ∀ c, (∀ a, (a → F a) → a → c) → (nu → c) :=
  fun c => fun g => fun x => match x with
    unNu _ s k => g _ k s
  end.

(* Theorem 3.2.1 *)
Theorem fold_build_fusion : ∀ a k g, fold a k (build g) = g a k.
Proof. auto. Qed.

(* Theorem 3.2.2 *)
Theorem unbuild_unfold_fusion : ∀ c a k g s, unbuild c g (unfold a k s) = g a k s.
Proof. auto. Qed.

Theorem free_theorem_for_fold : ∀ A A' h k k',
  h ∘ k = k' ∘ fmap h → h ∘ fold A k = fold A' k'.
Proof.
  intros.
  unfold fold, compose.
  extensionality g.
  unfold μ in g.
  assert (∀ B j, ∃ x, g B j = j x).
    admit.
  pose proof H1.
  specialize (H1 A k). destruct H1. rewrite H1.
  specialize (H2 A' k'). destruct H2. rewrite H2.
  replace (h (k x)) with ((h ∘ k) x). rewrite H0.
  unfold compose. f_equal.
  destruct H. simpl.
Admitted.

Theorem ump_fold : ∀ a (h : μ F → a) (k : F a → a) (alg : F (μ F) → μ F),
  h ∘ alg = k ∘ fmap h  ↔  h = fold a k.
Proof.
  intros.
  split; intros.
  - pose (free_theorem_for_fold (μ F) a h alg k).
    rewrite <- e.
    replace (fold (μ F) alg) with (@id (μ F)).
    rewrite comp_id_right. reflexivity.
    pose (free_theorem_for_fold (μ F) a (fold a k) alg k).
Abort.