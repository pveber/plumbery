module type T = sig
  val main : host:string -> port:int -> string -> unit
end

module Make(E : Env.T) = struct
  let main ~host ~port job_name = 
    let ic, oc = Unix.(open_connection (ADDR_INET (inet_addr_of_string host, port))) in
    output_string oc (job_name ^ "\n") ; 
    flush oc ;
    let f, x = (input_value ic : ('a -> 'b) * 'a) in
    let r = f x in
    Marshal.to_channel oc r [Marshal.Closures] ;
    flush oc ;
    close_out oc
end
