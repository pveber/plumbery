module type T = sig
  val main : host:string -> port:int -> string -> unit
end

module Make(E : Env.T) : T