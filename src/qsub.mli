module type T = sig
  val eval : ('a -> 'b) -> 'a -> 'b Lwt.t
end

module Make(E : Env.T) : T