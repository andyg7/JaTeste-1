module L = Llvm
module A = Ast
module S = Sast
module StringMap = Map.Make(String)

exception InvalidStruct of string


	let context = L.global_context () 
	let the_module = L.create_module context "Jateste" 

	let i32_t = L.i32_type context
	let i64_t = L.i64_type context
	let i8_t = L.i8_type context
	let i1_t = L.i1_type context
	let d_t = L.double_type context
	let void_t = L.void_type context
	let str_t = L.pointer_type i8_t 

	let struct_types:(string, L.lltype) Hashtbl.t = Hashtbl.create 10
	let global_variables:(string, L.llvalue) Hashtbl.t = Hashtbl.create 50

	let find_struct_name name = 
	 try Hashtbl.find struct_types name
	 with | Not_found -> raise(InvalidStruct name)

	let declare_struct s =
	 let struct_t = L.named_struct_type context s.S.ssname in
	Hashtbl.add struct_types s.S.ssname struct_t

	let prim_ltype_of_typ = function
		  A.Int -> i32_t
		| A.Double -> d_t
		| A.Char -> i8_t
		| A.Void -> void_t
		| A.String -> str_t

	let rec ltype_of_typ = function
		| A.Primitive(s) -> prim_ltype_of_typ s
		| A.Struct_typ(s) ->  find_struct_name s
		| A.Pointer_typ(s) -> L.pointer_type (ltype_of_typ s)
		| A.Array_typ(t,n) -> L.array_type (prim_ltype_of_typ t) n
    		| _ -> void_t 

	(* Function that builds LLVM struct *)
	let define_struct_body s =
	 let struct_t = Hashtbl.find struct_types s.S.ssname in
	  let attribute_types = List.map (fun (t, _) -> t) s.S.sattributes in
	   let attributes = List.map ltype_of_typ attribute_types in		
	    let attributes_array = Array.of_list attributes in 
	L.struct_set_body struct_t attributes_array false

	(* Where we add global variabes to global data section *)
	 let global_var_2 (t, n) =
		match t with
		  A.Primitive(_) -> Hashtbl.add global_variables n (L.declare_global (ltype_of_typ t) n the_module)
		| A.Struct_typ(_) -> Hashtbl.add  global_variables n (L.declare_global (ltype_of_typ t) n the_module)
		| A.Pointer_typ(_) -> Hashtbl.add  global_variables n (L.declare_global (ltype_of_typ t) n the_module)
		| A.Array_typ(_,_) -> Hashtbl.add global_variables n (L.declare_global (ltype_of_typ t) n the_module)
		| A.Func_typ(_) -> Hashtbl.add global_variables n (L.declare_global (ltype_of_typ t) n the_module)

	
	(* Translations functions to LLVM code in text section  *)
	let translate_function (functions) = 

	(* Here we define the built in print function *)
 	let printf_t = L.var_arg_function_type i32_t [| L.pointer_type i8_t |] in
         let printf_func = L.declare_function "printf" printf_t the_module in

	(* Here we iterate through Ast.functions and add all the function names
	   to a HashMap *)
	let function_decls =
         let function_decl m fdecl =
           let name = fdecl.S.sfname
            and formal_types =
            Array.of_list (List.map (fun (t,_) -> ltype_of_typ t) fdecl.S.sformals)
            in let ftype = L.function_type (ltype_of_typ fdecl.S.styp) formal_types in
             StringMap.add name (L.define_function name ftype the_module, fdecl) m in
    	List.fold_left function_decl StringMap.empty functions in
	
	(* Method to build body of function *)
	let build_function_body fdecl =
    	 let (the_function, _) = StringMap.find fdecl.S.sfname function_decls in
	  (* builder is the LLVM instruction builder *)
          let builder = L.builder_at_end context (L.entry_block the_function) in

	(*let int_format_str = L.build_global_stringptr "%d\n" "fmt" builder in *)
	let str_format_str = L.build_global_stringptr "%s\n" "fmt" builder in

	(* This is where we push local variables onto the stack and add them to a local HashMap*)
	let local_vars = 
	 let add_formal m(t, n) p = L.set_value_name n p;
	  let local = L.build_alloca (ltype_of_typ t) n builder in
	  ignore (L.build_store p local builder);
	StringMap.add n local m in

	let add_local m (t, n) =
         let local_var = L.build_alloca (ltype_of_typ t) n builder
        in StringMap.add n local_var m in

	(* This is where we push formal arguments onto the stack *)
	let formals = List.fold_left2 add_formal StringMap.empty fdecl.S.sformals
          (Array.to_list (L.params the_function)) in
      List.fold_left add_local formals fdecl.S.svdecls in


	(* Two places to look for a variable 1) local HashMap 2) global HashMap *)
	let find_var n = try StringMap.find n local_vars
                 with Not_found -> try Hashtbl.find global_variables n
                 with Not_found -> raise (Failure ("undeclared variable " ^ n))
    in
      
	let add_terminal builder f =
          match L.block_terminator (L.insertion_block builder) with
        	  Some _ -> ()
      		| None -> ignore (f builder) in	

	(* This is where we build LLVM expressions *)
	let rec expr builder = function 
	   S.SLit l -> L.const_int i32_t l
	 | S.SId s -> L.build_load (find_var s) s builder
	 | S.SCall("print", [e]) -> L.build_call printf_func [|str_format_str; (expr builder e) |] "printf" builder
	 | S.SCall(f, args) -> let (def_f, fdecl) = StringMap.find f function_decls in
			       let actuals = List.rev (List.map (expr builder) (List.rev args)) in let result = (match fdecl.S.styp with A.Primitive(A.Void) -> "" | _ -> f ^ "_result") in L.build_call def_f (Array.of_list actuals) result builder
	 | S.SString_Lit s -> let temp_string = L.build_global_stringptr s "str" builder in temp_string 
	 | S.SAssign (l, e) -> let e_temp = expr builder e in ignore(L.build_store e_temp (find_var l) builder); e_temp
	 | _ -> L.const_int i32_t 0 
	in


	(* This is where we build the LLVM statements *)
	let rec stmt builder = function 
	  S.SBlock b -> List.fold_left stmt builder b
	| S.SExpr e -> ignore (expr builder e); builder
	| S.SReturn r -> ignore (match fdecl.S.styp with
						  A.Primitive(A.Void) -> L.build_ret_void builder
						| _ -> L.build_ret (expr builder r) builder); builder
	
	| S.SIf(_, _, _) -> builder
	| _ -> builder
	in
	
	(* Build the body for this function *)
	let builder = stmt builder (S.SBlock fdecl.S.sbody) in
		
	add_terminal builder (match fdecl.S.styp with
          A.Primitive(A.Void) -> L.build_ret_void
        | _ -> L.build_ret (L.const_int i32_t 0) )
	in
	
	(* Here we go through each function and build the body of the function *)
	List.iter build_function_body functions;
 	the_module

	(* Overall function that translates Ast.program to LLVM module *)
	let gen_llvm (g, f, s) = 
	let _ = List.iter declare_struct s in
	let _ = List.iter define_struct_body s in
	let _ = List.iter global_var_2 g in
	let _ = translate_function (f) in
	the_module
