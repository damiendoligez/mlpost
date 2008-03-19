(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) Johannes Kanig, Stephane Lescuyer                       *)
(*  and Jean-Christophe Filliatre                                         *)
(*                                                                        *)
(*  This software is free software; you can redistribute it and/or        *)
(*  modify it under the terms of the GNU Library General Public           *)
(*  License version 2, with the special exception on linking              *)
(*  described in file LICENSE.                                            *)
(*                                                                        *)
(*  This software is distributed in the hope that it will be useful,      *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                  *)
(*                                                                        *)
(**************************************************************************)

(* low-level interface *)
(* A path is a succession of knots bound by joints *)
type direction = Types.direction =
  | Vec of Point.t
  | Curl of float
  | NoDir 

type joint = Types.joint =
  | JLine
  | JCurve
  | JCurveNoInflex
  | JTension of float * float
  | JControls of Point.t * Point.t

type knot = direction * Point.t * direction

type t = Types.path

val start : knot -> t
val concat : t -> joint -> knot -> t

val cycle : direction -> joint -> t -> t
val append : t -> joint -> t -> t

val subpath : float -> float -> t -> t

val fullcircle : t
val halfcircle : t
val quartercircle: t
val unitsquare: t

val transform : Transform.t -> t -> t

val bpath : Box.t -> t

val point : float -> t -> Point.t

val cut_after : t -> t -> t
val cut_before: t -> t -> t
val build_cycle : t list -> t

val defaultjoint : joint