Require Import Hask.Prelude.
Require Import Hask.Control.Monad.
Require Import Hask.Data.Functor.Contravariant.
Require Import Hask.Data.Functor.Identity.
Require Import Hask.Control.Monad.Trans.State.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Generalizable All Variables.

Definition Lens s t a b := forall `{Functor f}, (a -> f b) -> s -> f t.
Definition Lens' s a := Lens s s a a.

Definition Getter s a :=
  forall `{Functor f} `{Contravariant f}, (a -> f a) -> s -> f s.

Definition Getting r s a := (a -> Const r a) -> s -> Const r s.

Notation "x &+ f" := (f x) (at level 71, only parsing).

Definition set `(l : Lens s t a b) (x : b) : s -> t := l _ _ (const x).
Notation "l .~ x" := (set l x) (at level 70).

Definition over `(l : Lens s t a b) (x : a -> b) : s -> t := l _ _ x.
Notation "l %~ f" := (over l f) (at level 70).

Definition view `(f : Getting a s a) : s -> a := f id.
Notation "x ^_ l" := (view l x) (at level 70).

Definition stepdown `(l : Lens' s a) : Getting a s a := l _ _.
Coercion stepdown : Lens' >-> Getting.

Notation "f \o+ g" := (fun x y => f x y \o g x y) (at level 71, only parsing).

Definition _1 {a b : Type} : Lens' (a * b) a :=
  fun _ _ f s => let: (x, y) := s in fmap (fun z => (z, y)) (f x).
Definition _2 {a b : Type} : Lens' (a * b) b :=
  fun _ _ f s => let: (x, y) := s in fmap (fun z => (x, z)) (f y).

Arguments _1 {a b} [_ _] f s.
Arguments _2 {a b} [_ _] f s.

Definition _ex1 {a : Type} {P : a -> Prop} : Getter { x : a | P x } a :=
  fun _ _ _ f s => fmap (const s) (f (proj1_sig s)).

Arguments _ex1 {a P _ _ _} f s.

Definition use `(l : Getting a s a) `{Monad m} : StateT s m a :=
  view l <$> getT.

Definition plusStateT `(l : Lens' s nat) (n : nat) `{Monad m} :
  StateT s m unit := modifyT (l %~ plus n).

Notation "l += n" := (plusStateT l n) (at level 71).

Module LensLaws.

Class LensLaws `(l : Lens' s a) := {
  lens_view_set : forall (x : s) (y : a), view l (set l y x) = y;
  lens_set_view : forall (x : s), set l (view l x) x = x;
  lens_set_set  : forall (x : s) (y z : a), set l z (set l y x) = set l z x
}.

Program Instance Lens__1 : LensLaws (s:=a * b) _1.
Program Instance Lens__2 : LensLaws (s:=a * b) _2.

Example lens_ex1 : view _1 (10, 20) == 10.
Proof. reflexivity. Qed.

Example lens_ex2 : view _2 (10, 20) == 20.
Proof. reflexivity. Qed.

Example lens_ex3 : (10, 20) ^_ _2 == 20.
Proof. reflexivity. Qed.

Example lens_ex4 : (1, (2, (3, 4))) ^_ stepdown (_2 \o+ _2 \o+ _2) == 4.
Proof. reflexivity. Qed.

Example lens_ex5 : ((10, 20) &+ _1 .~ 500) == (500, 20).
Proof. reflexivity. Qed.

Example lens_ex6 : ((10, 20) &+ _1 %~ plus 1) == (11, 20).
Proof. reflexivity. Qed.

End LensLaws.