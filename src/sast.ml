open Ast

type var_info = (string * typ)

type sexpr =
    SLit     of int
  | SString_lit of string
  | SChar_lit of char
  | SBinop   of sexpr * op * sexpr
  | SUnop    of uop * sexpr
  | SAssign  of sexpr * sexpr
  | SNoexpr
  | SId of string
  | SStruct_create of string
  | SStruct_access of string * string * int
  | SPt_access of string * string * int
  | SArray_create of int * prim
  | SArray_access of string * int
  | SDereference of string
  | SFree of string
  | SCall of string * sexpr list
  | SBoolLit of int

type sstmt =
    SBlock of sstmt list   
  | SExpr of sexpr
  | SIf of sexpr * sstmt * sstmt
  | SWhile of sexpr * sstmt
  | SFor of sexpr * sexpr * sexpr * sstmt
  | SReturn of sexpr

type swith_using_decl = {
  suvdecls : bind list;
  sstmts : sstmt list;
}

type swith_test_decl = {
  sasserts : sstmt list;
  susing : swith_using_decl;
}

(* Node that describes a function *)
type sfunc_decl = {
  styp : typ;
  sfname : string;
  sformals : bind list;
  svdecls  : bind list;
  sbody  :   sstmt list;
  stests   :   sfunc_decl option;
}

(* Node that describes a given struct *)
type sstruct_decl = {
  ssname   : string;
  sattributes  : bind list;
}

(* Root of tree. Our program is made up three things 1) list of global variables 2) list of functions 3) list of struct definition *)
type sprogram = header list * bind list * sfunc_decl list * sstruct_decl list
