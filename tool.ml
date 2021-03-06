(**************************************************************************)
(*                                                                        *)
(*  Copyright (C) Johannes Kanig, Stephane Lescuyer                       *)
(*  Jean-Christophe Filliatre, Romain Bardou and Francois Bobot           *)
(*                                                                        *)
(*  This software is free software; you can redistribute it and/or        *)
(*  modify it under the terms of the GNU Library General Public           *)
(*  License version 2.1, with the special exception on linking            *)
(*  described in file LICENSE.                                            *)
(*                                                                        *)
(*  This software is distributed in the hope that it will be useful,      *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                  *)
(*                                                                        *)
(**************************************************************************)

open Format
open Arg

let use_ocamlbuild = ref false
let ccopt = ref " "
let execopt = ref " "
let verbose = Mlpost_desc_options.verbose
let native = ref false
let libraries = ref (Version.libraries Version.libdir)
let compile_name = ref None
let dont_execute = ref false
let dont_clean = ref false
let add_nothing = ref false

let files =
  Queue.create ()

let not_cairo = Version.not_cairo
let not_bitstring = Version.not_bitstring

let used_libs =
  (* put libraries in correct order here *)
  let acc = ["unix"] in
  let acc = if not_cairo then acc else "cairo"::acc in
  let acc = if not_bitstring then acc else "bitstring"::acc in
  let acc = "mlpost"::acc in
  (* mlpost_options is activated by default *)
  let acc = "mlpost_options"::acc in
  ref acc

let add_contrib x =
  if List.mem_assoc x !libraries then
    used_libs := x::!used_libs
  else begin Format.eprintf "contrib %s unknown" x; exit 1 end

let remove_mlpost_options () =
  used_libs := List.filter (fun s -> s <> "mlpost_options") !used_libs

let add_file f =
  if not (Filename.check_suffix f ".ml") then begin
    eprintf "mlpost: don't know what to do with %s@." f;
    exit 1
  end;
  if not (Sys.file_exists f) then begin
    eprintf "mlpost: %s: no such file@." f;
    exit 1
  end;
  Queue.add f files

let version () =
  (* The first line of the output should be the version number, and only the
   * version number! *)
  Format.printf "%s@." Version.version;
  Format.printf "mlpost %s compiled at %s@." Version.version Version.date;
  Format.printf "searching for mlpost.cm(a|xa) in %s@." Version.libdir;
  if not not_cairo || not not_bitstring  then
    Format.printf "additional directories are %s@." Version.include_string;
  exit 0

let add_ccopt x = ccopt := !ccopt ^ x ^ " "
let add_execopt x = execopt := !execopt ^ x ^ " "

let add_libdir libdir =
  libraries := Version.libraries libdir

let give_lib () =
  List.fold_left
  (fun (acc1,acc2) x ->
    let includes_,libs = List.assoc x !libraries in
    List.rev_append includes_ acc1, List.rev_append libs acc2)
  ([],[]) !used_libs

let get_include_compile s =
  (* TODO revoir *)
  let aux = function
(*
    | "cmxa" -> List.map (fun (x,y) -> Filename.concat x (y^".cmxa"))
        (give_lib ())
    | "cma" -> List.map (fun (x,y) -> Filename.concat x (y^".cma"))
        (give_lib ())
*)
    | "dir" -> fst (give_lib ())
    | "file" -> snd (give_lib ())
    | _ -> assert false in
  print_string (String.concat "\n" (aux s))

let nocairo () =
  print_string "Mlpost has not been compiled with cairo\n";
  exit 1

let options_for_compiled_prog = Queue.create ()
let aotofcp ?arg s =
  Queue.add s options_for_compiled_prog;
  match arg with
    | None -> ()
    | Some s -> Queue.add s options_for_compiled_prog

let execopt cmd =
  let b = Buffer.create 30 in
  bprintf b "%s %a -- %s@?"
    cmd
    (fun fmt -> Queue.iter (fprintf fmt "\"%s\" ")) options_for_compiled_prog
    !execopt;
  Buffer.contents b

let build_args ?ext () =
  (* ext = None => ocamlbuild *)
  let lib_ext lib acc =
    match ext with
    | None -> "-lib"::lib::acc
    | Some ext -> (lib^ext)::acc in
  let include_ acc libdir =
    match ext with
    | None -> (sprintf "-cflags -I,%s -lflags -I,%s " libdir libdir)::acc
    | Some ext -> "-I"::libdir::acc in
  List.fold_left (fun acc c ->
    let llibdir,llib = List.assoc c !libraries in
    let acc = List.fold_right lib_ext llib acc in
    let acc = List.fold_left include_ acc llibdir in
    acc) [] !used_libs

 (* The option have the same behavior but
    add itself to option_for_compiled_prog in addition *)
let wrap_option (opt,desc,help) =
  let desc =
    match desc with
      | Unit f -> Unit (fun () -> f ();aotofcp opt)
      | Set s -> Unit (fun () -> s:=true; aotofcp opt)
      | Clear s -> Unit (fun () -> s:=false; aotofcp opt)
      | String f -> String (fun s -> f s;aotofcp ~arg:s opt)
      | Int f -> Int (fun s -> f s;aotofcp ~arg:(string_of_int s) opt)
      | Float f -> Float (fun s -> f s;aotofcp ~arg:(string_of_float s) opt)
      | Bool f -> Bool (fun s -> f s;aotofcp ~arg:(string_of_bool s) opt)
      | Set_int s -> Int (fun x -> s:=x; aotofcp ~arg:(string_of_int x) opt)
      | Set_float s -> Float (fun x -> s:=x;
                                aotofcp ~arg:(string_of_float x) opt)
      | Set_string s -> String (fun x -> s:=x; aotofcp ~arg:x opt)
      | Symbol (l, f) -> Symbol (l,fun x -> f x; aotofcp ~arg:x opt)
      | Rest _ | Tuple _ -> assert false (*Not implemented... *)
 in
  (opt,desc,help)


let spec = Arg.align
  (["-ocamlbuild", Set use_ocamlbuild, " Use ocamlbuild to compile";
    "-native", Set native, " Compile to native code";
    "-ccopt", String add_ccopt,
    "\"<options>\" Pass <options> to the Ocaml compiler";
    "-execopt", String add_execopt,
    "\"<options>\" Pass <options> to the compiled program";
    "-version", Unit version, " Print Mlpost version and exit";
    "-libdir", String add_libdir, " change assumed libdir of mlpost";
    "-get-include-compile",
    Symbol (["cmxa";"cma";"dir";"file"],get_include_compile),
    " Output the libraries which are needed by the library Mlpost";
    "-compile-name", String (fun s -> compile_name := Some s),
    "<compile-name> Keep the compiled version of the .ml file";
    "-dont-execute", Set dont_execute, " Don't execute the compiled file";
    "-no-magic", Unit remove_mlpost_options,
    " Do not parse mlpost options, do not call Metapost.dump";
    "-contrib", String add_contrib,
    "<contrib_name> Compile with the specified contrib"
  ]@(if not_cairo
     then ["-cairo" , Unit nocairo,
           " Mlpost has not been compiled with the cairo backend";
           "-t1disasm" , Unit nocairo,
           " Mlpost has not been compiled with the cairo backend";
          ]
     else [])
   @(List.map wrap_option Mlpost_desc_options.spec))

let () =
  Arg.parse spec add_file "Usage: mlpost [options] files..."

exception Command_failed of int

let command' ?inv ?outv s =
  let s = Misc.call_cmd ?inv ?outv ~verbose:!verbose s in
  if s <> 0 then raise (Command_failed s)

let command ?inv ?outv s =
  try command' ?inv ?outv s with Command_failed s -> exit s

let execute ?outv cmd =
  let cmd = execopt cmd in
  if !dont_execute
  then (if !verbose then printf "You can execute the program with :@.%s" cmd)
  else command ?outv cmd

let normalize_filename s =  if Filename.is_relative s then "./"^s else s

let get_exec_name compile_name =
  match compile_name with
    | None -> Filename.temp_file "mlpost" ""
    | Some s -> normalize_filename s

let try_remove s = try Sys.remove s with _ -> ()

let ocaml_generic compiler args =
  let s = get_exec_name !compile_name in
  let cmd = compiler ^ " -o " ^ s ^ " " ^ String.concat " " args in
  command ~outv:true cmd;
  execute ~outv:true s;
  match !compile_name with
    | None -> if !dont_clean then () else Sys.remove s
    | Some s -> ()

let ocaml = ocaml_generic Version.ocamlc
let ocamlopt = ocaml_generic Version.ocamlopt

let ocamlbuild args exec_name =
  let args =
    if !verbose then "-classic-display" :: args else " -quiet"::args in
  command ~outv:true ("ocamlbuild " ^ String.concat " " args ^ exec_name);
  execute ~outv:true ("_build/"^exec_name);
  (match !compile_name with
    | None -> ()
    | Some s -> command ("cp _build/" ^ exec_name ^ " " ^ s))
    (* I think we should never call ocamlbuild -clean, maybe only remove the
     * symlink -- Johannes *)
(*   if !dont_clean then () else command "ocamlbuild -clean" *)

let compile f =
  let bn = Filename.chop_extension f in
  if !use_ocamlbuild then
    let ext = if !native then ".native" else ".byte" in
    let exec_name = bn ^ ext in
    try ocamlbuild (build_args () @ ["-no-links";!ccopt]) exec_name
    with Command_failed out -> exit out
  else
    let ext = if !native then ".cmxa" else ".cma" in
    let args = build_args ~ext () @ [!ccopt; f] in
    if !native then ocamlopt args else ocaml args;
    if not !dont_clean then List.iter (fun suf -> try_remove (bn^suf))
      [".cmi";".cmo";".cmx";".o"]

let () = Queue.iter compile files
