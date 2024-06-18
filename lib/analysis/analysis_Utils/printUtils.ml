module Parser = struct
  type atomic_list = DataStructures.Parser.Commands.atomic_t list [@@deriving show]
end

module Analysis = struct
  type commands_list = DataStructures.Analysis.Commands.t list [@@deriving show]

  open DataStructures
  open DataStructures.Analysis
  open NormalForm

  let pretty_print_normal_form (formula: NormalForm.t) =
    let join_list (formulas: Formula.t list) (f: Formula.t -> string) (sep: string) =
      let rec join_list (formulas: Formula.t list) (f: Formula.t -> string) (sep: string) =
        match formulas with
        | [] -> ""
        | [x] -> f x
        | x::xs -> f x ^ sep ^ join_list xs f sep
      in
      let sep = " " ^ sep ^ " " in
      join_list formulas f sep
    in
    let bound_identifiers_to_string (vars: IdentifierSet.t) = 
      IdentifierSet.fold (fun x acc -> acc ^ "exists " ^ x ^ ".") vars ""
    in
    let bound_identifiers_better_names (formula: NormalForm.t) =
      let new_id_name last_name =
        if last_name.[0] = 'z' then
          "a" ^ last_name
        else
          let last_part = String.sub last_name 1 (String.length last_name - 1) in
          let ch = last_name.[0] |> Char.code |> ((+) 1) |> Char.chr |> (String.make 1) in
          ch ^ last_part
      in
      let rec new_id_name_in_vars old_id last_name (vars: IdentifierSet.t) =
        let new_name = new_id_name last_name in
        if IdentifierSet.find_opt last_name vars |> Option.is_none then
          new_name, vars |> IdentifierSet.remove old_id |> IdentifierSet.add last_name
        else
          new_id_name_in_vars old_id new_name vars
      in

      IdentifierSet.fold (fun id (name, formula) ->
        let next_name, variables = new_id_name_in_vars id name formula.variables in
        let disjoints = List.map (fun x -> RenameVariable.rename_variable_in_formula x id name) formula.disjoints in
        next_name, NormalForm.make variables disjoints formula.id_generator
      ) formula.variables ("a", formula) |> snd
    in

    let rec expand_conjuncts (formula: Formula.t) =
      match formula with
      | And(lformula, rformula) -> expand_conjuncts lformula @ expand_conjuncts rformula
      | _ -> [formula]
    in
    let expand_separate_conjuncts (formula: Formula.t) =
      match formula with
      | AndSeparately(lformula, rformula) -> expand_conjuncts lformula @ expand_conjuncts rformula
      | _ -> [formula]
    in
    let comparison_op_to_string (op: BinaryComparison.t) =
      match op with
      | Equals -> "="
      | NotEquals -> "!="
      | LessThan -> "<"
      | LessOrEqual -> "<="
      | GreaterThan -> ">"
      | GreaterOrEqual -> ">="
    in
    let binary_op_to_string (op: BinaryOperator.t) =
      match op with
      | Plus -> "+"
      | Minus -> "-"
      | Times -> "*"
      | Division -> "/"
      | Modulo -> "%"
    in
    let rec expression_to_string (expr: ArithmeticExpression.t) =
      match expr with
      | Literal(value) -> string_of_int value
      | Variable(id) -> id
      | Operation(op, lexpr, rexpr) -> 
        let lexpr = match lexpr with
          | Operation(_) -> "(" ^ expression_to_string lexpr ^ ")"
          | _ -> expression_to_string lexpr
        in
        let rexpr = match rexpr with
          | Operation(_) -> "(" ^ expression_to_string rexpr ^ ")"
          | _ -> expression_to_string rexpr
        in
        lexpr ^ " " ^ binary_op_to_string op ^ " " ^ rexpr
    in
    let rec disjoint_to_string (formula: Formula.t) =
      match formula with
      | True -> "true"
      | False -> "false"
      | EmptyHeap -> "emp"
      | Allocation(id, expr) -> id ^ " -> " ^ expression_to_string expr
      | NonAllocated(id) -> id ^ " -/>"
      | Comparison(op, lexpr, rexpr) ->
        let lexpr = match lexpr with
          | Operation(_) -> "(" ^ expression_to_string lexpr ^ ")"
          | _ -> expression_to_string lexpr
        in
        let rexpr = match rexpr with
          | Operation(_) -> "(" ^ expression_to_string rexpr ^ ")"
          | _ -> expression_to_string rexpr
        in
        lexpr ^ " " ^ comparison_op_to_string op ^ " " ^ rexpr
      | And(_) -> expand_conjuncts formula |> (fun x -> join_list x conjunct_to_string "&&")
      | AndSeparately(_) -> expand_separate_conjuncts formula |> (fun x -> join_list x conjunct_to_string "*")
    and conjunct_to_string (conjunct: Formula.t) =
      match conjunct with
      | AndSeparately(_)
      | And(_) -> "( " ^ disjoint_to_string conjunct ^ ")"
      | _ -> disjoint_to_string conjunct
    in

    let formula = bound_identifiers_better_names formula in

    let disjoints_print = join_list formula.disjoints disjoint_to_string "||" in
    "<< " ^ bound_identifiers_to_string formula.variables ^ disjoints_print ^ " >>"

  let pretty_print_command (command: Commands.t) =
    let pretty_print_binary_operator (op: Ast.HeapRegularCommands.ArithmeticOperation.t) =
      match op with
      | Plus -> "+"
      | Minus -> "-"
      | Times -> "*"
      | Division -> "/"
      | Modulo -> "%"
    in
    let pretty_print_boolean_comparison (op: Ast.HeapRegularCommands.BooleanComparison.t) =
      match op with
      | Equal -> "=="
      | NotEqual -> "!="
      | LessThan -> "<"
      | LessOrEqual -> "<="
      | GreaterThan -> ">"
      | GreaterOrEqual -> ">="
    in

    let rec pretty_print_expr (expr: Commands.arithmetic_t) =
      match expr.node with
      | Literal(int) -> string_of_int int
      | Variable(id) -> id
      | BinaryOperation(op, lexpr, rexpr) ->
        let lexpr = pretty_print_expr_parenthesized lexpr in
        let rexpr = pretty_print_expr_parenthesized rexpr in
        lexpr ^ " " ^ pretty_print_binary_operator op ^ " " ^ rexpr
    and pretty_print_expr_parenthesized (expr: Commands.arithmetic_t) =
      match expr.node with
      | BinaryOperation(_) -> "("  ^ pretty_print_expr expr  ^ ")"
      | _ -> pretty_print_expr expr
    in

    let rec pretty_print_bexpr (expr: Commands.boolean_t) =
      match expr.node with
      | True -> "true"
      | False -> "false"
      | Not(expr) -> "!" ^ pretty_print_bexpr expr
      | Or(lexpr, rexpr) ->
        let lexpr = pretty_print_bexpr_parenthesized lexpr in
        let rexpr = pretty_print_bexpr_parenthesized rexpr in
        lexpr  ^ " || "  ^ rexpr
      | And(lexpr, rexpr) ->
        let lexpr = pretty_print_bexpr_parenthesized lexpr in
        let rexpr = pretty_print_bexpr_parenthesized rexpr in
        lexpr  ^ " && "  ^ rexpr
      | Comparison(op, lexpr, rexpr) ->
        let lexpr = pretty_print_expr_parenthesized lexpr in
        let rexpr = pretty_print_expr_parenthesized rexpr in
        lexpr ^ " " ^ pretty_print_boolean_comparison op  ^ " " ^ rexpr
    and pretty_print_bexpr_parenthesized (expr: Commands.boolean_t) =
      match expr.node with
      | Or(_) | And(_) | Comparison(_) -> "("  ^ pretty_print_bexpr expr  ^ ")"
      | _ -> pretty_print_bexpr expr
    in

    match command.node with
    | Skip -> "skip"
    | Assignment(id, expr) -> id ^ " = " ^ pretty_print_expr expr
    | NonDet(id) -> id ^ " = nondet()"
    | Guard(bexpr) -> pretty_print_bexpr bexpr
    | Allocation(id) -> id ^ " = alloc()"
    | Free(id) -> "free(" ^ id ^ ")"
    | ReadHeap(id, heap) -> id ^ " = [" ^ heap ^ "]"
    | WriteHeap(heap, expr) -> "[" ^ heap ^ "] = " ^ pretty_print_expr expr

  let pretty_print_analysis_trace (trace: analysis_trace) =
    let print_cmd (command: Commands.t) =
      pretty_print_command command ^ "\n" ^ 
      pretty_print_normal_form (Option.get command.annotation.postcondition)
    in

    let acc = pretty_print_normal_form trace.precondition in
    List.fold_left (fun acc x -> acc ^ "\n" ^ print_cmd x) acc trace.trace
end