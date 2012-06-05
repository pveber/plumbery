module type T = 
sig
  val run : unit -> unit
end

module type Workflow = functor (Q : Qsub.T) -> sig val task : unit -> unit Lwt.t end

module Make(E : Env.T)(Workflow : Workflow) = struct
  let whoami = match Sys.argv with 
    | [| _ ; "--worker" ; host ; port ; job_name |] ->
      `worker (host, int_of_string port, job_name)
    | _ -> `master

  let run () = match whoami with
    | `master -> 
      let module Qsub = Qsub.Make(E) in
      let module W = Workflow(Qsub) in
      Lwt_main.run (W.task ())
    | `worker (host, port, job_name) -> 
      let module W = Worker.Make(E) in 
      W.main ~host ~port job_name
end
 