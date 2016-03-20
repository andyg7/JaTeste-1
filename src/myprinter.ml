open Ast

let rec add_indent indent = 
 	match indent with
	 0 -> ""
	|_ -> " " ^ add_indent (indent - 1)

let string_of_op = function
    Add -> "+"
  | Sub -> "-"
  | Mult -> "*"
  | Div -> "/"
  | Equal -> "=="
  | Neq -> "!="
  | Less -> "<"
  | Leq -> "<="
  | Greater -> ">"
  | Geq -> ">="
  | And -> "&&"
  | Or -> "||"
  | Mod -> "mod"
  | Exp -> "^"

let string_of_uop = function
    Neg -> "-"
  | Not -> "!"
  | Addr -> "&"

let rec string_of_expr indent expr = match expr with
    Lit(l) -> string_of_int l
  | Id(s) -> "Id" ^ "-" ^s
  | Binop(e1, o, e2) -> "Binop" ^ "\n" ^ (add_indent (indent + 1)) ^ string_of_expr
  (indent + 1) e1 ^ "\n" ^ (add_indent (indent + 1)) ^ string_of_op o ^ "\n" ^
  (add_indent (indent + 1)) ^ string_of_expr (indent + 1) e2
  | Unop(o, e) -> string_of_uop o ^ string_of_expr  (indent + 1) e
  | Assign(v, e) -> "Assign" ^ "\n" ^ (add_indent (indent + 1)) ^ string_of_expr (indent
  + 1) v ^ "\n" ^ (add_indent (indent + 1)) ^ string_of_expr  (indent + 1) e
  | Noexpr -> ""
  | Struct_create(s) -> "new struct"
  | Struct_Access(e1,e2) -> ""
  | Array_create(i, prim) -> ""
  | Array_access(e1, i) -> ""
  | Call(s, expr) -> ""


let rec string_of_stmt indent stmt = match stmt with
    Block(stmts) -> String.concat "" (List.map (fun x -> ((add_indent indent) ^ string_of_stmt indent x)) stmts)
      (*"\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "\n" *)
  | Expr(expr) -> string_of_expr (indent) expr ^ "\n";
  | Return(expr) -> "return " ^ "\n" ^ (add_indent (indent + 1)) ^ string_of_expr  (indent + 1) expr ^ "\n";
  | If(e, s, Block([])) -> "if (" ^ string_of_expr  (indent + 1) e ^ ")\n" ^ string_of_stmt (indent + 1) s
  | If(e, s1, s2) ->   "if (" ^ string_of_expr  (indent + 1) e ^ ")\n" ^
      string_of_stmt (indent + 1) s1 ^ "else\n" ^ string_of_stmt (indent + 1) s2
  | For(e1, e2, e3, s) -> 
      "for (" ^ string_of_expr  (indent) e1  ^ " ; " ^ string_of_expr (indent) e2 ^ " ; " ^
      string_of_expr  (indent + 1) e3  ^ ") " ^ string_of_stmt (indent + 1) s
  | While(e, s) -> "while" ^ "\n" ^ (add_indent (indent + 1)) ^ string_of_expr
  (indent + 1) e ^ "\n" ^ string_of_stmt (indent + 1) s ^ "\n"

let string_of_prim_type typ =
	match typ with
	| Int -> "int"
	| String -> "string"
	| Char -> "char"
	| Void -> "void"
	| _ -> ""

let string_of_typ typ = 
	match typ with
    Primitive(s) -> string_of_prim_type s
  | Struct_typ(s) -> "struct"
  | Func_typ(s) -> "func"
  | Pointer_typ(s) -> "ptr"
  | Array_typ(s) -> "array"

let string_of_vdecl indent (t, id) = "Id" ^ "-" ^ id ^ "(" ^ string_of_typ t ^ ")\n"

let list_with_indent indent args = 
	List.map (fun x -> ((add_indent indent) ^ string_of_vdecl indent x)) args

let string_of_fdecl fdecl indent = "function: " ^ fdecl.fname ^ "(\n" ^
String.concat "" (list_with_indent (indent + 1) fdecl.formals) ^  ")\n" ^ 
String.concat ""  (list_with_indent (indent + 1) fdecl.vdecls) ^ "\n" ^
String.concat "" (List.map (fun x -> ((add_indent (indent + 1)) ^ string_of_stmt indent x)) fdecl.body)
(*
  string_of_typ fdecl.typ ^ " " ^
  fdecl.fname ^ "(" ^ String.concat ", " (List.map snd fdecl.formals) ^
  ")\n{\n" ^
  String.concat "" (List.map string_of_vdecl fdecl.formals) ^
  String.concat "" (List.map string_of_stmt fdecl.body) ^
  "}\n"
  *)

let rec string_of_program indent prog= 
	match  prog with
	| Var(s)::(rest as a) -> (string_of_vdecl (indent + 1) s)  ^ (string_of_program indent a) 	
	| Func(s)::(rest as a) -> (string_of_fdecl s (indent + 1)) ^ (string_of_program indent a) 
	| Stmt(s)::(rest as a) -> (string_of_stmt (indent + 1) s) ^ (string_of_program indent a)
	| Struct(s)::(rest) -> ""
	| [] -> ""
  (*
  String.concat "" (List.map string_of_vdecl vars) ^ "\n" ^
  String.concat "\n" (List.map string_of_fdecl funcs)
  *)

  		
