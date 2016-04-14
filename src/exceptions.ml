(* Struct exceptions*)
exception InvalidStruct of string

(* Variable exceptions*)
exception UndeclaredVariable of string

(*Expression exceptions *)
exception InvalidExpr of string
exception InvalidBooleanExpression 
exception IllegalAssignment
exception InvalidFunctionCall of string
exception InvalidArgumentsToFunction of string
exception InvalidArrayVariable
exception InvalidStructField

(* Statement exceptions*)
exception InvalidReturnType of string

(* Bug catcher *)
exception BugCatch of string
