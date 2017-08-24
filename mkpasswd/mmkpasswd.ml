let error_exit msg =
  prerr_endline msg;
  exit 1

let get_passwd_lines () =
  let buf = Buffer.create 1024 in
  let ec = Run.run ~stdout:(`Buffer buf) "mkpasswd.exe" ["-c"] in
  if ec <> 0 then
    error_exit "call to mkpasswd.exe failed";
  match CCString.Split.list_cpy ~by:"\n" (Buffer.contents buf) with
  | [] -> error_exit "output of mkpasswd empty"
  | l -> l

let htl_homes = Hashtbl.create 128

let rec create_uniq s n =
  let i = s ^ (string_of_int n) in
  if Hashtbl.mem htl_homes i then
    create_uniq s (succ n)
  else
    let () = Hashtbl.replace htl_homes i () in
    i

let n_home = function
(* TODO: find similar users like /home/HomeGroupUser$ *)
| "/home/HomeGroupUser$" as x -> x
| s ->
  let char_ok = function
  | 'A'..'Z' | 'a'..'z' | '0'..'9' | '_' | '-' -> true
  | _ -> false
  in
  let len = String.length s in
  let b = Buffer.create len in
  Buffer.add_string b "/home/" ;
  for i = 6 to len - 1 do
    let c = s.[i] in
    if char_ok c then
      Buffer.add_char b c ;
  done;
  let s' = Buffer.contents b in
  if s' = s then
    s
  else if s' = "/home/" then
    create_uniq "/home/mluser" 1
  else if Hashtbl.mem htl_homes s' then
    create_uniq s' 1
  else
    let () = Hashtbl.replace htl_homes s' () in
    s'

let rewrite_lines l =
  let modified = ref false in
  let single l =
    match CCString.Split.list_cpy ~by:":" l |> Array.of_list with
    | ([| _1 ; _2 ; _3 ; _4 ; _5 ; home ; _7 |]) as ar
      when CCString.prefix ~pre:"/home/" home ->
      let home' = n_home home in
      if home' = home then
        l
      else
        let () = ar.(5) <- home' in
        modified := true;
        Array.to_list ar |> String.concat ":"
    | _ -> l
  in
  !modified, List.map single l

let () =
  let modified,entries =
    get_passwd_lines () |> List.filter ((<>) "") |> rewrite_lines
  in
  if modified = false then
    exit 0;
  let s = String.concat "\n" entries in
  let ch = open_out_bin "passwd" in
  output_string ch s;
  if s.[String.length s - 1] <> '\n' then
    output_char ch '\n' ;
  close_out ch;
  exit 0
