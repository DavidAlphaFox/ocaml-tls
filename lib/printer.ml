open Core
open Printf
open Packet

let tls_version_to_string = function
  | TLS_1_0 -> "TLS version 1.0"
  | TLS_1_1 -> "TLS version 1.1"
  | TLS_1_2 -> "TLS version 1.2"

let tls_any_version_to_string = function
  | Supported t -> tls_version_to_string t
  | SSL_3       -> "SSL version 3"
  | TLS_1_X l   ->
     "TLS version > 1.2 (3, " ^ string_of_int l ^ ")"

let header_to_string (header : tls_hdr) =
  sprintf "protocol %s: %s"
          (tls_any_version_to_string header.version)
          (content_type_to_string header.content_type)

let certificate_request_to_string cr =
  "FOOO"

let hash_to_string = function
  | `MD5    -> "MD5"
  | `SHA1   -> "SHA1"
  | `SHA224 -> "SHA224"
  | `SHA256 -> "SHA256"
  | `SHA384 -> "SHA384"
  | `SHA512 -> "SHA512"


let hash_sig_to_string (h, s) =
  hash_to_string h ^ " with " ^ signature_algorithm_type_to_string s

let extension_to_string = function
  | Hostname host -> "Hostname: " ^ (match host with
                                     | None   -> "NONE"
                                     | Some x -> x)
  | MaxFragmentLength mfl -> "Maximum fragment length: " ^ (max_fragment_length_to_string mfl)
  | EllipticCurves curves -> "Elliptic curves: " ^
                               (String.concat ", " (List.map named_curve_type_to_string curves))
  | ECPointFormats formats -> "Elliptic Curve formats: " ^ (String.concat ", " (List.map ec_point_format_to_string formats))
  | SecureRenegotiation _ -> "secure renegotiation"
  | Padding _ -> "padding"
  | SignatureAlgorithms xs -> "Signature algs: " ^ (String.concat ", " (List.map hash_sig_to_string xs))
  | UnknownExtension _ -> "Unhandled extension"

let client_hello_to_string c_h =
  sprintf "client hello: protocol %s\n  ciphers %s\n  extensions %s"
          (tls_any_version_to_string c_h.version)
          (List.map any_ciphersuite_to_string c_h.ciphersuites |> String.concat ", ")
          (List.map extension_to_string c_h.extensions |> String.concat ", ")

let server_hello_to_string (c_h : server_hello) =
  sprintf "server hello: protocol %s\n cipher %s\b extensions %s"
          (tls_version_to_string c_h.version)
          (Ciphersuite.ciphersuite_to_string c_h.ciphersuites)
          (List.map extension_to_string c_h.extensions |> String.concat ", ")

let rsa_param_to_string r =
  "RSA parameters: modulus: " ^ Cstruct.copy r.rsa_modulus 0 (Cstruct.len r.rsa_modulus) ^
  "exponent: " ^ Cstruct.copy r.rsa_exponent 0 (Cstruct.len r.rsa_exponent)

let dsa_param_to_string r =
  "DSA parameters: p: " ^ Cstruct.copy r.dh_p 0 (Cstruct.len r.dh_p) ^
  "g: " ^ Cstruct.copy r.dh_g 0 (Cstruct.len r.dh_g) ^
  "Ys: " ^ Cstruct.copy r.dh_Ys 0 (Cstruct.len r.dh_Ys)

let ec_prime_parameters_to_string pp = "EC Prime Parameters"

let ec_char_parameters_to_string cp = "EC Char Parameters"

let ec_param_to_string = function
  | ExplicitPrimeParameters pp -> ec_prime_parameters_to_string pp
  | ExplicitCharParameters cp -> ec_char_parameters_to_string cp
  | NamedCurveParameters (nc, public) -> named_curve_type_to_string nc

let handshake_to_string = function
  | HelloRequest -> "Hello request"
  | ServerHelloDone -> "Server hello done"
  | ClientHello x -> client_hello_to_string x
  | ServerHello x -> server_hello_to_string x
  | Certificate x -> sprintf "Certificate: %d" (List.length x)
  | ServerKeyExchange x -> sprintf "Server KEX: %d" (Cstruct.len x)
  | ClientKeyExchange x -> sprintf "Client KEX: %d" (Cstruct.len x)
  | CertificateRequest x -> certificate_request_to_string x
  | Finished x -> "Finished"

let alert_to_string (lvl, typ) =
  alert_level_to_string lvl ^ " " ^ alert_type_to_string typ

let body_to_string = function
  | TLS_ChangeCipherSpec -> "TLS Change Cipher Spec"
  | TLS_ApplicationData -> "TLS Application Data"
  | TLS_Handshake x -> handshake_to_string x
  | TLS_Alert a -> alert_to_string a

let to_string (hdr, body) =
  sprintf "header: %s\n body: %s" (header_to_string hdr) (body_to_string body)
