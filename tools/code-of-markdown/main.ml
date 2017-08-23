open Nonstd
module String = StringLabels

let read_all_exn path_opt =
  let i = Option.value_map ~f:open_in path_opt ~default:stdin in
  let buf = Buffer.create 42 in
  begin
    try while true do Buffer.add_char buf (input_char i) done
    with _ -> ()
  end;
  Option.iter path_opt (fun _ -> close_in i);
  Buffer.contents buf

let write_all_exn path_opt ~content =
  let o = Option.value_map ~f:open_out path_opt ~default:stdout in
  fprintf o "%s\n%!" content;
  Option.iter path_opt (fun _ -> close_out o)

let get_nth input output ~nth =
  let count = ref 1 in
  let rec search: Omd.t -> string option = fun omd ->
    let open Omd in
    List.find_map omd ~f:begin function
    (* match omd with *)
    | Paragraph more -> search more
    | Code_block (_, s) when !count = nth -> Some s
    | Code_block (_, s) -> incr count; None
    | other -> None
    end
  in
  let omd = read_all_exn input |> Omd.of_string in
  (* |> Omd.to_html |> printf "\n%s\n%!" *)
  match search omd with
  | Some s -> write_all_exn output s
  | None -> failwith "Code block not found :("

let () =
  let open Cmdliner in
  let default_cmd =
    let doc = "Do things on markdown code blocs" in
    let sdocs = Manpage.s_common_options in
    let exits = Term.default_exits in
    Term.(ret (const (fun _ -> `Help (`Pager, None)) $ pure ())),
    Term.info "code-of-markdown" ~version:"0.0.0" ~doc ~sdocs ~exits
  in
  let get_cmd =
    let doc = "Get a piece of code from a markdown file" in
    let inpath =
      let doc = "Path to a MD file." in
      Arg.(value & opt (some string) None & info ["i"; "input"] ~docv:"PATH"
             ~doc)
    in
    let outpath =
      let doc = "Path to an output file." in
      Arg.(value & opt (some string) None & info ["o"; "output"] ~docv:"PATH"
             ~doc)
    in
    let nth =
      let doc = "Get the Nth code bloc." in
      Arg.(value & opt int 1 & info ["nth"] ~docv:"N" ~doc)
    in
    Term.(pure (fun ip op nth -> get_nth ip op ~nth)
          $ inpath $ outpath $ nth),
    Term.info "get" ~version:"0.0.0" ~doc
  in
  let cmds = [get_cmd] in
  Term.(exit @@ eval_choice default_cmd cmds)
