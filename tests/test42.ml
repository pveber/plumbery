module Env = struct
  let port = 9999
  let queues = []
end

module Workflow(Qsub : Plumbery.Qsub.T) = struct
  let task () =
    lwt n = Qsub.eval succ 41 in
    print_endline ("The answer is " ^ (string_of_int n)) ; 
    Lwt.return ()
end

module M = Plumbery.Main.Make(Env)(Workflow)
let () = M.run ()
