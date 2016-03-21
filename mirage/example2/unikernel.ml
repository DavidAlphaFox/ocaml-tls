open Lwt.Infix
open V1_LWT

module Main (C  : CONSOLE)
            (S  : STACKV4)
            (KV : KV_RO)
            (CL : V1.CLOCK) =
struct

  module TLS  = Tls_mirage.Make (S.TCPV4)
  module X509 = Tls_mirage.X509 (KV) (CL)
  module Http = Cohttp_mirage.Server (TLS)

  module Body = Cohttp_lwt_body

  let handle c conn req body =
    let resp = Cohttp.Response.make ~status:`OK () in
    (match Cohttp.Request.meth req with
     | `POST ->
       Body.to_string body >|= fun contents ->
       "<pre>" ^ contents ^ "</pre>"
     | _     -> Lwt.return "") >|= fun inlet ->
    let body = Body.of_string @@
    "<html><head><title>ohai</title></head> \
     <body><h3>Secure CoHTTP on-line.</h3>"
    ^ inlet ^ "</body></html>\r\n"
    in
    (resp, body)

  let upgrade c conf tcp =
    TLS.server_of_flow conf tcp >>= function
    | `Error _  | `Eof -> Lwt.fail (Failure "tls init")
    | `Ok tls  ->
      let t = Http.make (handle c) () in
      Http.listen t tls

  let start c stack kv _ _ =
    X509.certificate kv `Default >>= fun cert ->
    let conf = Tls.Config.server ~certificates:(`Single cert) () in
    S.listen_tcpv4 stack ~port:4433 (upgrade c conf) ;
    S.listen stack

end
