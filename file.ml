module LowLevel = struct
  (** delete a directory that may contain files *)
  let rmdir dir =
    Array.iter (fun x -> Sys.remove (Filename.concat dir x)) (Sys.readdir dir);
    Unix.rmdir dir

  (** copy a file to another *)
  let copy src dest =
    let cin = open_in src
    and cout = open_out dest
    and buff = String.make 1024 ' '
    and n = ref 0
    in
    while n := input cin buff 0 1024; !n <> 0 do
      output cout buff 0 !n
    done;
    close_in cin; close_out cout

  (** rename a file *)
  let move src dest =
    try Unix.rename src dest
    with Unix.Unix_error (Unix.EXDEV,_,_) -> copy src dest

  let read_from fn f =
    let c = open_in fn in
    let r = f c in
    close_in c;
    r

  let write_to filename f =
    let chan = open_out filename in
    let r = f chan in
    close_out chan; r

  let write_to_formatted filename f =
    write_to filename
      (fun chan ->
        let fmt = Format.formatter_of_out_channel chan in
        let r = f fmt in
        Format.fprintf fmt "@?"; r)

end

module Dir = struct
  type t =
    { dirs : string list ; is_relative : bool }
  (* the type t is a stack of directories, innermost is on top *)

  let from_string =
    let r = Str.regexp_string Filename.dir_sep in
    fun s ->
      { dirs = List.rev (Str.split r s); is_relative = Filename.is_relative s }

  let concat d1 d2 =
    assert (not d2.is_relative);
    { d1 with dirs = d2.dirs @ d1.dirs }

  let print_sep fmt () = Format.pp_print_string fmt Filename.dir_sep
  let to_string s =
    (** TODO fix things for absolute paths *)
    let prefix = if s.is_relative then "" else "/" in
      Misc.sprintf "%s%a" prefix
        (Misc.print_list print_sep Format.pp_print_string) s.dirs

  let temp = from_string Filename.temp_dir_name

  let mk t rights = Unix.mkdir (to_string t) rights

  let ch t = Sys.chdir (to_string t)

  let cwd () = from_string (Sys.getcwd ())

  let empty = { dirs = []; is_relative = true }

  let rm d = LowLevel.rmdir (to_string d)

  let compare = Pervasives.compare
    (* this one is actually difficult ... for now we just compare the elements
       *)

end

type t =
  { dir: Dir.t ; bn : string ; ext : string option }

let dir t = t.dir
let extension t = t.ext
let basename t = t.bn

let split_ext =
  let r = Str.regexp_string ".[^./]$" in
  fun s ->
    let l = String.length s in
    try
      let i = Str.search_backward r s (String.length s) in
      String.sub s 0 i, Some (String.sub s (i+1) (l-i))
    with Not_found -> s, None

let from_string s =
  let d = Dir.from_string s in
  match d.Dir.dirs with
  | [] -> { dir = d; bn = ""; ext = None }
  | fn::dirs ->
      let bn,ext = split_ext fn in
      { dir = { Dir.dirs = dirs; is_relative = d.Dir.is_relative};
      bn = bn; ext = ext }

let place d t = { t with dir = d }

let concat d t = { t with dir = Dir.concat d t.dir }

let append t s = { t with bn = t.bn ^ s }

let file_to_string bn ext =
  match ext with
  | None -> bn
  | Some ext -> Misc.sprintf "%s.%s" bn ext

let to_string t =
  Misc.sprintf "%s/%s" (Dir.to_string t.dir) (file_to_string t.bn t.ext)

let set_ext t s =
  let ext = if s = "" then None else Some s in
  { t with ext = ext }

let clear_dir t = { t with dir = Dir.empty }

let compare a b =
  let c = Pervasives.compare a.bn b.bn in
  if c <> 0 then c
  else let c = Pervasives.compare a.ext b.ext in
  if c<> 0 then c
  else Dir.compare a.dir b.dir

module Map = Map.Make(struct type t' = t type t = t' let compare = compare end)

(** wrappers for low level functions *)
let move a b = LowLevel.move (to_string a) (to_string b)
let read_from t f = LowLevel.read_from (to_string t) f
let write_to t f = LowLevel.write_to (to_string t) f
let write_to_formatted t f = LowLevel.write_to_formatted (to_string t) f
