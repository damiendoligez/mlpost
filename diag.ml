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

open Helpers

module Node = struct

  type t = { id : int; x : float; y : float; s : string; }

  let create = 
    let c = ref min_int in 
    fun x y s -> incr c; { id = !c; x = x; y = y; s = s; }

  let hash n = 
    n.id

  let equal n1 n2 =
    n1.id == n2.id

end

module Hnode = Hashtbl.Make(Node)

open Node

type node = Node.t

let node = Node.create

type dir = Up | Down | Left | Right | Angle of float

type arrow = { 
  src : node; 
  dst : node; 
  lab : string; 
  pos : Command.position option;
  outd : dir option;
  ind : dir option;
}

type t = {
  nodes : node list;
  boxes : Box.t Hnode.t;
  mutable arrows: arrow list;
}

let create l = 
  { nodes = l; boxes = Hnode.create 17; arrows = [] }

let arrow d ?(lab="") ?pos ?outd ?ind n1 n2 =
  d.arrows <- 
    { src = n1; dst = n2; lab = lab; pos = pos; outd = outd; ind = ind } 
    :: d.arrows

let outdir = function
  | Up -> Path.Vec Point.up
  | Down -> Path.Vec Point.down
  | Left -> Path.Vec Point.left
  | Right -> Path.Vec Point.right
  | Angle f -> Path.Vec (Point.dir f)

let indir = function
  | Up -> Path.Vec Point.down
  | Down -> Path.Vec Point.up
  | Left -> Path.Vec Point.right
  | Right -> Path.Vec Point.left
  | Angle f -> Path.Vec (Point.dir f)

let outdir = function None -> None | Some x -> Some (outdir x)
let indir = function None -> None | Some x -> Some (indir x)

type node_style = Circle | Rect

let make_box ~style ~scale d n = 
  let p = Point.p (scale n.x, scale n.y) in
  let pic = Picture.tex n.s in
  let b = match style with 
    | Circle -> Box.circle p pic 
    | Rect -> Box.rect p pic 
  in
  Hnode.add d.boxes n b;
  b

let box_of d = Hnode.find d.boxes

let draw_arrow ?stroke ?pen d a =
  let src = box_of d a.src in
  let dst = box_of d a.dst in
  if a.lab = "" then 
    box_arrow 
      ?color:stroke ?pen ?outd:(outdir a.outd) ?ind:(indir a.ind) src dst
  else
    box_label_arrow 
      ?color:stroke ?pen ?outd:(outdir a.outd) ?ind:(indir a.ind) 
      ?pos:a.pos (Picture.tex a.lab) src dst

let fortybp x = Num.bp (40. *. x)

let draw ?(scale=fortybp) ?(style=Circle) ?fill ?stroke ?pen d =
  let l = 
    List.map 
      (fun n -> Command.draw_box ?fill (make_box ~style ~scale d n)) d.nodes
  in
  l @ List.map (draw_arrow ?stroke ?pen d) d.arrows
