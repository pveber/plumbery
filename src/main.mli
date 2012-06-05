module type T = 
sig
  val run : unit -> unit
end

module type Workflow = functor (Q : Qsub.T) -> sig val task : unit -> unit Lwt.t end

module Make(E : Env.T)(W : Workflow) : T
