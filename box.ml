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

open Format

type circle_style =
  | Padding of Num.t * Num.t (* dx , dy *)
  | Ratio of float (* dx / dy *)

type t = 
  | Circle of Name.t * Point.t * Picture.t * circle_style option
  | Rect of Name.t * Point.t * Picture.t

let circle ?style c p = Circle (Name.create (), c, p, style)
let rect c p = Rect (Name.create (), c, p)

let center = function
  | Circle (_, c, _, _) 
  | Rect (_, c, _) -> c

let declare fmt = function
  | Circle (n, c, p, s) -> 
      fprintf fmt "circleit.%a(%a);" Name.print n Picture.print p;
      fprintf fmt "%a.c = %a;@\n" Name.print n Point.print c;
      begin match s with
	| None -> ()
	| Some (Padding (dx, dy)) -> 
	    fprintf fmt "%a.dx = %a; %a.dy = %a;@\n" 
	      Name.print n Num.print dx Name.print n Num.print dy
	| Some (Ratio r) ->
	    fprintf fmt "%a.dx = %f * %a.dy;@\n" Name.print n r Name.print n
      end
  | Rect (n, c, p) -> 
      fprintf fmt "boxit.%a(%a);" Name.print n Picture.print p;
      fprintf fmt "%a.c = %a;@\n" Name.print n Point.print c

let name = function
  | Circle (n, _, _, _) | Rect (n, _, _) -> n

let north b = Point.north (name b)
let south b = Point.south (name b)
let west b = Point.west (name b)
let east b = Point.east (name b)
let north_west = function
  | Rect (n, _, _) -> Point.north_west n
  | Circle _ -> invalid_arg "north_west: circle"
let north_east = function 
  | Rect (n, _, _) -> Point.north_east n
  | Circle _ -> invalid_arg "north_east: circle"
let south_west = function 
  | Rect (n, _, _) -> Point.south_west n
  | Circle _ -> invalid_arg "south_west: circle"
let south_east = function 
  | Rect (n, _, _) -> Point.south_east n
  | Circle _ -> invalid_arg "south_east: circle"


