open OUnit2
open Tls
open Testlib

let readerwriter_version v _ =
  let buf = Writer.assemble_protocol_version v in
  Reader.(match parse_version buf with
          | Or_error.Ok ver ->
             assert_equal v ver ;
             (* lets get crazy and do it one more time *)
             let buf' = Writer.assemble_protocol_version v in
             (match parse_version buf' with
              | Or_error.Ok ver' -> assert_equal v ver'
              | Or_error.Error _ -> assert_failure "read and write version broken")
          | Or_error.Error _ -> assert_failure "read and write version broken")

let version_tests =
  [ "ReadWrite version TLS-1.0" >:: readerwriter_version Core.TLS_1_0 ;
    "ReadWrite version TLS-1.1" >:: readerwriter_version Core.TLS_1_1 ;
    "ReadWrite version TLS-1.2" >:: readerwriter_version Core.TLS_1_2 ]

let readerwriter_header (v, ct, cs) _ =
  let buf = Writer.assemble_hdr v (ct, cs) in
  match Reader.parse_hdr buf with
  | (Some ct', Some v', l) ->
     assert_equal v v' ;
     assert_equal ct ct' ;
     assert_equal (Cstruct.len cs) l ;
     let buf' = Writer.assemble_hdr v' (ct', cs) in
     (match Reader.parse_hdr buf' with
      | (Some ct'', Some v'', l') ->
         assert_equal v v'' ;
         assert_equal ct ct'' ;
         assert_equal (Cstruct.len cs) l' ;
      | _ -> assert_failure "inner header broken")
  | _ -> assert_failure "header broken"

let header_tests =
  let a = list_to_cstruct [ 0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15 ] in
  [ "ReadWrite header" >:: readerwriter_header (Core.TLS_1_0, Packet.HANDSHAKE, a) ;
    "ReadWrite header" >:: readerwriter_header (Core.TLS_1_1, Packet.HANDSHAKE, a) ;
    "ReadWrite header" >:: readerwriter_header (Core.TLS_1_2, Packet.HANDSHAKE, a) ;

    "ReadWrite header" >:: readerwriter_header (Core.TLS_1_0, Packet.APPLICATION_DATA, a) ;
    "ReadWrite header" >:: readerwriter_header (Core.TLS_1_1, Packet.APPLICATION_DATA, a) ;
    "ReadWrite header" >:: readerwriter_header (Core.TLS_1_2, Packet.APPLICATION_DATA, a) ;

    "ReadWrite header" >:: readerwriter_header (Core.TLS_1_0, Packet.CHANGE_CIPHER_SPEC, a) ;
    "ReadWrite header" >:: readerwriter_header (Core.TLS_1_1, Packet.CHANGE_CIPHER_SPEC, a) ;
    "ReadWrite header" >:: readerwriter_header (Core.TLS_1_2, Packet.CHANGE_CIPHER_SPEC, a) ;

    "ReadWrite header" >:: readerwriter_header (Core.TLS_1_0, Packet.HEARTBEAT, a) ;
    "ReadWrite header" >:: readerwriter_header (Core.TLS_1_1, Packet.HEARTBEAT, a) ;
    "ReadWrite header" >:: readerwriter_header (Core.TLS_1_2, Packet.HEARTBEAT, a) ;

    "ReadWrite header" >:: readerwriter_header (Core.TLS_1_0, Packet.ALERT, a) ;
    "ReadWrite header" >:: readerwriter_header (Core.TLS_1_1, Packet.ALERT, a) ;
    "ReadWrite header" >:: readerwriter_header (Core.TLS_1_2, Packet.ALERT, a) ;
 ]

let readerwriter_alert (lvl, typ) _ =
  let buf, expl = match lvl with
    | None -> (Writer.assemble_alert typ, Packet.FATAL)
    | Some l -> (Writer.assemble_alert ~level:l typ, l)
  in
  Reader.(match parse_alert buf with
          | Or_error.Ok (l', t') ->
             assert_equal expl l' ;
             assert_equal typ t' ;
             (* lets get crazy and do it one more time *)
             let buf' = Writer.assemble_alert ~level:l' t' in
             (match parse_alert buf' with
              | Or_error.Ok (l'', t'') -> assert_equal expl l'' ; assert_equal typ t''
              | Or_error.Error _ -> assert_failure "inner read and write alert broken")
          | Or_error.Error _ -> assert_failure "read and write alert broken")

let rw_alert_tests = Packet.([
  ( None,  CLOSE_NOTIFY ) ;
  ( None,  UNEXPECTED_MESSAGE ) ;
  ( None,  BAD_RECORD_MAC ) ;
  ( None,  DECRYPTION_FAILED ) ;
  ( None,  RECORD_OVERFLOW ) ;
  ( None,  DECOMPRESSION_FAILURE ) ;
  ( None,  HANDSHAKE_FAILURE ) ;
  ( None,  NO_CERTIFICATE_RESERVED ) ;
  ( None,  BAD_CERTIFICATE ) ;
  ( None,  UNSUPPORTED_CERTIFICATE ) ;
  ( None,  CERTIFICATE_REVOKED ) ;
  ( None,  CERTIFICATE_EXPIRED ) ;
  ( None,  CERTIFICATE_UNKNOWN ) ;
  ( None,  ILLEGAL_PARAMETER ) ;
  ( None,  UNKNOWN_CA ) ;
  ( None,  ACCESS_DENIED ) ;
  ( None,  DECODE_ERROR ) ;
  ( None,  DECRYPT_ERROR ) ;
  ( None,  EXPORT_RESTRICTION_RESERVED ) ;
  ( None,  PROTOCOL_VERSION ) ;
  ( None,  INSUFFICIENT_SECURITY ) ;
  ( None,  INTERNAL_ERROR ) ;
  ( None,  USER_CANCELED ) ;
  ( None,  NO_RENEGOTIATION ) ;
  ( None,  UNSUPPORTED_EXTENSION ) ;
  ( None,  CERTIFICATE_UNOBTAINABLE ) ;
  ( None,  UNRECOGNIZED_NAME ) ;
  ( None,  BAD_CERTIFICATE_STATUS_RESPONSE ) ;
  ( None,  BAD_CERTIFICATE_HASH_VALUE ) ;
  ( None,  UNKNOWN_PSK_IDENTITY ) ;

  ( Some FATAL,  CLOSE_NOTIFY ) ;
  ( Some FATAL,  UNEXPECTED_MESSAGE ) ;
  ( Some FATAL,  BAD_RECORD_MAC ) ;
  ( Some FATAL,  DECRYPTION_FAILED ) ;
  ( Some FATAL,  RECORD_OVERFLOW ) ;
  ( Some FATAL,  DECOMPRESSION_FAILURE ) ;
  ( Some FATAL,  HANDSHAKE_FAILURE ) ;
  ( Some FATAL,  NO_CERTIFICATE_RESERVED ) ;
  ( Some FATAL,  BAD_CERTIFICATE ) ;
  ( Some FATAL,  UNSUPPORTED_CERTIFICATE ) ;
  ( Some FATAL,  CERTIFICATE_REVOKED ) ;
  ( Some FATAL,  CERTIFICATE_EXPIRED ) ;
  ( Some FATAL,  CERTIFICATE_UNKNOWN ) ;
  ( Some FATAL,  ILLEGAL_PARAMETER ) ;
  ( Some FATAL,  UNKNOWN_CA ) ;
  ( Some FATAL,  ACCESS_DENIED ) ;
  ( Some FATAL,  DECODE_ERROR ) ;
  ( Some FATAL,  DECRYPT_ERROR ) ;
  ( Some FATAL,  EXPORT_RESTRICTION_RESERVED ) ;
  ( Some FATAL,  PROTOCOL_VERSION ) ;
  ( Some FATAL,  INSUFFICIENT_SECURITY ) ;
  ( Some FATAL,  INTERNAL_ERROR ) ;
  ( Some FATAL,  USER_CANCELED ) ;
  ( Some FATAL,  NO_RENEGOTIATION ) ;
  ( Some FATAL,  UNSUPPORTED_EXTENSION ) ;
  ( Some FATAL,  CERTIFICATE_UNOBTAINABLE ) ;
  ( Some FATAL,  UNRECOGNIZED_NAME ) ;
  ( Some FATAL,  BAD_CERTIFICATE_STATUS_RESPONSE ) ;
  ( Some FATAL,  BAD_CERTIFICATE_HASH_VALUE ) ;
  ( Some FATAL,  UNKNOWN_PSK_IDENTITY ) ;

  ( Some WARNING,  CLOSE_NOTIFY ) ;
  ( Some WARNING,  UNEXPECTED_MESSAGE ) ;
  ( Some WARNING,  BAD_RECORD_MAC ) ;
  ( Some WARNING,  DECRYPTION_FAILED ) ;
  ( Some WARNING,  RECORD_OVERFLOW ) ;
  ( Some WARNING,  DECOMPRESSION_FAILURE ) ;
  ( Some WARNING,  HANDSHAKE_FAILURE ) ;
  ( Some WARNING,  NO_CERTIFICATE_RESERVED ) ;
  ( Some WARNING,  BAD_CERTIFICATE ) ;
  ( Some WARNING,  UNSUPPORTED_CERTIFICATE ) ;
  ( Some WARNING,  CERTIFICATE_REVOKED ) ;
  ( Some WARNING,  CERTIFICATE_EXPIRED ) ;
  ( Some WARNING,  CERTIFICATE_UNKNOWN ) ;
  ( Some WARNING,  ILLEGAL_PARAMETER ) ;
  ( Some WARNING,  UNKNOWN_CA ) ;
  ( Some WARNING,  ACCESS_DENIED ) ;
  ( Some WARNING,  DECODE_ERROR ) ;
  ( Some WARNING,  DECRYPT_ERROR ) ;
  ( Some WARNING,  EXPORT_RESTRICTION_RESERVED ) ;
  ( Some WARNING,  PROTOCOL_VERSION ) ;
  ( Some WARNING,  INSUFFICIENT_SECURITY ) ;
  ( Some WARNING,  INTERNAL_ERROR ) ;
  ( Some WARNING,  USER_CANCELED ) ;
  ( Some WARNING,  NO_RENEGOTIATION ) ;
  ( Some WARNING,  UNSUPPORTED_EXTENSION ) ;
  ( Some WARNING,  CERTIFICATE_UNOBTAINABLE ) ;
  ( Some WARNING,  UNRECOGNIZED_NAME ) ;
  ( Some WARNING,  BAD_CERTIFICATE_STATUS_RESPONSE ) ;
  ( Some WARNING,  BAD_CERTIFICATE_HASH_VALUE ) ;
  ( Some WARNING,  UNKNOWN_PSK_IDENTITY ) ;
])

let rw_alert_tests =
  List.mapi
    (fun i f -> "RW alert " ^ string_of_int i >:: readerwriter_alert f)
    rw_alert_tests

let assert_dh_eq a b =
  Core.(assert_cs_eq a.dh_p b.dh_p) ;
  Core.(assert_cs_eq a.dh_g b.dh_g) ;
  Core.(assert_cs_eq a.dh_Ys b.dh_Ys)

let readerwriter_dh_params params _ =
  let buf = Writer.assemble_dh_parameters params in
  Reader.(match parse_dh_parameters buf with
          | Or_error.Ok (p, raw, rst) ->
             assert_equal (Cstruct.len rst) 0 ;
             assert_dh_eq p params ;
             assert_equal buf raw ;
             (* lets get crazy and do it one more time *)
             let buf' = Writer.assemble_dh_parameters p in
             (match parse_dh_parameters buf' with
              | Or_error.Ok (p', raw', rst') ->
                 assert_equal (Cstruct.len rst') 0 ;
                 assert_dh_eq p' params ;
                 assert_equal buf raw' ;
              | Or_error.Error _ -> assert_failure "inner read and write dh params broken")
          | Or_error.Error _ -> assert_failure "read and write dh params broken")

let rw_dh_params =
  let a = list_to_cstruct [ 0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15 ] in
  let emp = list_to_cstruct [] in
  Core.([
         { dh_p = emp ; dh_g = emp ; dh_Ys = emp } ;
         { dh_p = a ; dh_g = emp ; dh_Ys = emp } ;
         { dh_p = emp ; dh_g = a ; dh_Ys = emp } ;
         { dh_p = emp ; dh_g = emp ; dh_Ys = a } ;
         { dh_p = a <+> a ; dh_g = a <+> a ; dh_Ys = a <+> a } ;
       ])

let rw_dh_tests =
  List.mapi
    (fun i f -> "RW dh_param " ^ string_of_int i >:: readerwriter_dh_params f)
    rw_dh_params

let readerwriter_tests =
  version_tests @
  header_tests @
  rw_alert_tests @
  rw_dh_tests