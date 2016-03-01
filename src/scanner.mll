{ open Parser }

rule token = parse
	   [' ' '\t' '\r' '\n' ] { token lexbuf } (* White space *)
	| "/*"			{ comment lexbuf }
	| '('			{ LPAREN }
	| ')'			{ RPAREN }
	| '{'			{ LBRACE}
	| '}'			{ RBRACE}
	| ';'			{ SEMI }
	| '+'			{ PLUS }
	| '-'			{ MINUS }
	| '*'			{ TIMES }
	| '/'			{ DIVIDE }
	| '='			{ ASSIGN }
	| "void"		{ VOID }
	| "int"			{ INT }
	| "func" 		{ FUNC }
	| "with test" 		{ WTEST }
	| "using"		{ USING }
	| ['a' - 'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']* as lxm { ID(lxm)}
	| ['0' - '9']+ as lxm   { LITERAL(int_of_string lxm)}
	| eof { EOF }
	| _ as char { raise (Failure ("illegal character " ^
			Char.escaped char))}



and comment = parse
	"*/" { token lexbuf }
	| _ { comment lexbuf }
