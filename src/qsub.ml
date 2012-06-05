open Printf

module type T = sig
  val eval : ('a -> 'b) -> 'a -> 'b Lwt.t
end

module Make(E : Env.T) = struct
  let newid = 
    let c = ref 0 in
    fun () -> incr c ; sprintf "%08d" !c
	
  let newname () = "plumb" ^ (newid ())
			       
  let waiters = Hashtbl.create 7
      
  let service_handler (ic,oc) = 
    try
      ignore begin
        lwt job_name = Lwt_io.read_line ic in
        let wakener = Hashtbl.find waiters job_name in
        Lwt.wakeup wakener (ic, oc) ;
        Lwt.return ()
      end
    with Not_found -> assert false

  let hostname = Unix.gethostname ()
  let addr = Unix.((gethostbyname hostname).h_addr_list.(0))
  let server = Lwt_io.establish_server (Unix.ADDR_INET (addr,E.port)) service_handler

  let create_pbs_script name path = 
    let lines = [
      sprintf "#PBS -N %s" name ;
      sprintf "#PBS -e /dev/null" ;
      sprintf "#PBS -o /dev/null" ;
      sprintf "%s --worker %s %d %s" Sys.argv.(0) (Unix.string_of_inet_addr addr) E.port name
    ] in
    print_endline path ;
    List.iter print_endline lines ;
    Lwt_io.lines_to_file path (Lwt_stream.of_list lines)

  let qsub ?queue script_fn = 
    let args = 
      Array.append
        (match queue with Some id -> [| "-q " ^ id |] | None -> [| |])
        [| script_fn |] in
    lwt line = Lwt_process.pread ~stdin:`Close ("qsub",args) in
    Lwt.return String.(sub line 0 (length line - 1))

  let eval f x = 
    let name = newname ()
    and script_fn = Filename.temp_file "plumbery_" ".pbs" in
    let connection_waiter, connection_waker = Lwt.wait () in
    Hashtbl.add waiters name connection_waker ;
    lwt () = create_pbs_script name script_fn in
    lwt job_id = qsub ~queue:"q1hour" script_fn in
    lwt () = Lwt_unix.unlink script_fn in
    lwt (ic, oc) = connection_waiter in
    lwt () = Lwt_io.write_value ~flags:[Marshal.Closures] oc (f, x) in
    lwt () = Lwt_io.flush oc in
    lwt r = Lwt_io.read_value ic in
    Lwt.return r
end
