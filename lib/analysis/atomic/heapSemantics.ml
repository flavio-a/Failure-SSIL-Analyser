open Analysis_Prelude
open NormalForm
open Atomic_Utils
open Formula

(* apply the semantics of alloc using the extract_alloc util *)
let apply_alloc_v2 (x : identifier) (x': identifier) (beta: identifier) (vars : IdentifierSet.t) (disjoints : Formula.t list) =
  let apply_alloc1 (q' : Formula.t) = q' in
  (* TODO write a comment to explain this *)
  let apply_alloc2 (q' : Formula.t) = AndSeparately(substitute_identifier_in_formula q' beta x, NonAllocated(beta)) in
  (* if x \in fv(q') use <<alloc1>>, else <<alloc2>> *)
  let apply_alloc (q' : Formula.t) = if check_frame_rule_side_condition q' vars x then apply_alloc1 q' else apply_alloc2 q' in
  disjoints
  |> List.map (extract_alloc x x')
  |> List.concat
  |> List.map apply_alloc

(* apply the semantics of free using the extract_dealloc util *)
let apply_free_v2 (x : identifier) (new_name: identifier) (disjoints : Formula.t list) =
  disjoints
  |> List.map (extract_dealloc x)
  |> List.concat
  |> List.map (fun q' -> AndSeparately(Allocation(x, ArithmeticExpression.Variable new_name), q'))

(* apply the semantics of write using the extract_alloc util *)
let apply_write_v2 (x : identifier) (new_name: identifier) (disjoints : Formula.t list) =
  disjoints
  |> List.map (extract_alloc x new_name)
  |> List.concat
  |> List.map (fun q' -> AndSeparately(Allocation(x, ArithmeticExpression.Variable new_name), q'))

(* apply the semantics of read using the extract_alloc util *)
let apply_read_v2 (l_id : identifier) (r_id : identifier) (new_name: identifier) (new_name2: identifier) (disjoints : Formula.t list) =
  disjoints
  |> List.map (extract_alloc r_id new_name)
  |> List.concat
  |> List.map (fun q' -> AndSeparately(Allocation(r_id, ArithmeticExpression.Variable new_name), substitute_expression_in_formula q' (ArithmeticExpression.Variable new_name) l_id new_name2))
