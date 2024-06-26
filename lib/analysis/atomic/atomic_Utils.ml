open Analysis_Prelude
open Analysis_Utils
open NormalForm

(* expand_andSeparately take a formula and returns a list of formulas,
   where each element is a separately-conjunct of the original formula
   i.e. AndSeparately(e1, AndSeparately(e2, e3)) -> [e1; e2; e3]
 *)
let rec expand_andSeparately (formula : Formula.t) : Formula.t list = 
  match formula with
  | AndSeparately(exp1, exp2) -> 
    (expand_andSeparately exp1) @ (expand_andSeparately exp2)
  | _ -> [formula]

(* compress_andSeparately take a list of formulas and returns 
   an andSeparately between each item of the list
   i.e. [e1; e2; e3] -> AndSeparately(e1, AndSeparately(e2, e3))
 *)
and compress_andSeparately (formula : Formula.t list) : Formula.t =
  match formula with
  | []  -> EmptyHeap
  | [x] -> x
  | x::xs -> List.fold_left (fun x y -> Formula.AndSeparately(x, y)) x xs

(* compute free identifier of expr, given a set of bound variable vars *)
let get_free_identifiers (expr : ArithmeticExpression.t) (vars : IdentifierSet.t)= 
  (get_normal_form_expr_identifiers expr |> IdentifierSet.diff) vars

(* given a heap partition t, this function checks mod(r) intersect fv(t) = empty 
   the function takes two possible results to return (one per branch)
 *)
let check_frame_rule_side_condition t vars mod_r : bool =
  let id_t = get_normal_form_disjoint_identifiers t in  (* identifiers in non-matching list (t) *)
  let fv_t = IdentifierSet.diff id_t vars in (* remove bound identifiers from id_t *)
  if (IdentifierSet.find_opt mod_r fv_t |> Option.is_none) then true else false

(* Check if x is not bound i.e. x is not in vars 
   if x is free, return res, otherwise return False 
 *)
let is_identifier_free (x : identifier) (vars : IdentifierSet.t) : bool =
  if (IdentifierSet.find_opt x vars |> Option.is_some) then false
  else true

let are_all_identifiers_free (identifiers : IdentifierSet.t) (vars : IdentifierSet.t) : bool =
  IdentifierSet.for_all (fun id -> is_identifier_free id vars) identifiers

(* Definition of an exception for handling cases in which identifier is bound
   i.e. precondition of free(x) returns False if in postcondition there is a bound x
 *)
exception Bound_Identifier of identifier

(* Given a formula q and a variable x, computes a q' such that
   q ∧ (x -/> ∗ true) is equivalent to x -/> * q'
   It returns q' as a list of formulas that are in disjunction
 *)
let rec extract_dealloc (x : identifier) (q : Formula.t) : Formula.t list =
  match q with
  | True -> [True]
  | False -> [False]
  | Comparison(_) -> [q]
  | EmptyHeap -> [False]
  | Allocation(_) -> [False]
  | NonAllocated(y) -> [And(Comparison(Equals, ArithmeticExpression.Variable y, ArithmeticExpression.Variable x), EmptyHeap)]
  | And(q1, q2) ->  list_cartesian (extract_dealloc x q1) (extract_dealloc x q2) |> List.map (fun (a, b) -> Formula.And(a, b))
  | AndSeparately(q1, q2) ->
    let resleft = List.map (fun a -> Formula.AndSeparately(a, q2)) (extract_dealloc x q1) in
    let resright = List.map (fun b -> Formula.AndSeparately(q1, b)) (extract_dealloc x q2) in
      resleft @ resright


(* Given a formula q and two variables x and x', computes a q' such that
   q ∧ (x -> x' ∗ true) is equivalent to x -> x' * q'
   It returns q' as a list of formulas that are in disjunction
 *)
let rec extract_alloc (x : identifier) (x' : identifier) (q : Formula.t) : Formula.t list =
  match q with
  | True -> [True]
  | False -> [False]
  | Comparison(_) -> [q]
  | EmptyHeap -> [False]
  | Allocation(y, a) -> [And(Comparison(Equals, ArithmeticExpression.Variable y, ArithmeticExpression.Variable x), And(Comparison(Equals, a, ArithmeticExpression.Variable x'), EmptyHeap))]
  | NonAllocated(_) -> [False]
  | And(q1, q2) -> list_cartesian (extract_alloc x x' q1) (extract_alloc x x' q2) |> List.map (fun (a, b) -> Formula.And(a, b))
  | AndSeparately(q1, q2) ->
    let resleft = List.map (fun a -> Formula.AndSeparately(a, q2)) (extract_alloc x x' q1) in
    let resright = List.map (fun b -> Formula.AndSeparately(q1, b)) (extract_alloc x x' q2) in
      resleft @ resright
