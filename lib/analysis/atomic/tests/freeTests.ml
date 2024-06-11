open AtomicBase
open Normalization
open DataStructures.Analysis.NormalForm
open Analysis_TestUtils

(* << Exists v . x -> v >> free(x) << x -/> >> *)
let%test "precondition on free(x), post-condition = << x -/> >>" =
  let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
  let post_condition = annot (PFormula.NonAllocated("x") ) in
  let post_condition = existential_disjuntive_normal_form post_condition in
  let pre_condition = compute_precondition command post_condition in
  let expected_disjoints = Formula.Allocation("x", Variable("fresh_var")) :: [] in
  test_expected_bound_variables pre_condition 1 &&
  test_expected_disjoints pre_condition expected_disjoints ["fresh_var"]

(* << false >> free(x) << x -> v >> *)
let%test "precondition on free(x), post-condition = << x -> v >>" =
let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
let post_condition = 
  annot (PFormula.Allocation(
      "x",
      annot (PArithmeticExpression.Variable("v"))
    )
  ) in
let post_condition = existential_disjuntive_normal_form post_condition in
let pre_condition = compute_precondition command post_condition in
let expected_disjoints = Formula.False :: [] in
test_expected_bound_variables pre_condition 0 &&
test_expected_disjoints pre_condition expected_disjoints []

(* << false >> free(x) << y -> v >> *)
let%test "precondition on free(x), post-condition = << y -> v >>" =
  let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
  let post_condition =
    annot (PFormula.Allocation(
      "y",
      annot (PArithmeticExpression.Variable("v"))
    )
  ) in
  let post_condition = existential_disjuntive_normal_form post_condition in
  let pre_condition = compute_precondition command post_condition in
  let expected_disjoints = Formula.False :: [] in
  test_expected_bound_variables pre_condition 0 &&
  test_expected_disjoints pre_condition expected_disjoints []

(* << false >> free(x) << Exists x . x -> v >> *)
let%test "precondition on free(x), post-condition = << Exists x . x -> v >>" =
  let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
  let post_condition =
    annot (PFormula.Exists("x", 
      annot (PFormula.Allocation(
        "x",
        annot (PArithmeticExpression.Variable("v"))
        )
      )
    )
  ) in
  let post_condition = existential_disjuntive_normal_form post_condition in
  let pre_condition = compute_precondition command post_condition in
  let expected_disjoints = Formula.False :: [] in
  test_expected_bound_variables pre_condition 1 &&
  test_expected_disjoints pre_condition expected_disjoints ["v"]

(* << false >> free(x) << false >> *)
let%test "precondition on free(x), post-condition = << false >>" =
  let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
  let post_condition = annot (PFormula.False) in
  let post_condition = existential_disjuntive_normal_form post_condition in
  let pre_condition = compute_precondition command post_condition in
  let expected_disjoints = Formula.False :: [] in
  test_expected_bound_variables pre_condition 0 &&
  test_expected_disjoints pre_condition expected_disjoints []

(* << true >> free(x) << true >> *)
let%test "precondition on free(x), post-condition = << true >>" =
  let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
  let post_condition = annot (PFormula.True) in
  let post_condition = existential_disjuntive_normal_form post_condition in
  let pre_condition = compute_precondition command post_condition in
  let expected_disjoints = Formula.True :: [] in
  test_expected_bound_variables pre_condition 0 &&
  test_expected_disjoints pre_condition expected_disjoints [] 

(* << Exists v . x -> v >> free(x) << emp >> *)
let%test "precondition on free(x), post-condition = << emp >>" =
let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
let post_condition = annot ( PFormula.EmptyHeap ) in
let post_condition = existential_disjuntive_normal_form post_condition in
let pre_condition = compute_precondition command post_condition in
let expected_disjoints = Formula.Allocation("x", Variable("fresh_var")) :: [] in
test_expected_bound_variables pre_condition 1 &&
test_expected_disjoints pre_condition expected_disjoints ["fresh_var"]

(* << false || false >> free(x) << emp || emp >> *)
let%test "precondition on free(x), post-condition = << emp || emp >>" =
let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
let post_condition = 
  annot ( 
    PFormula.Or(
      annot (PFormula.EmptyHeap),
      annot (PFormula.EmptyHeap)
    )
  ) in
let post_condition = existential_disjuntive_normal_form post_condition in
let pre_condition = compute_precondition command post_condition in
let expected_disjoints = 
  Formula.Allocation("x", Variable("fresh_var_1")) :: 
  Formula.Allocation("x", Variable("fresh_var_2")) :: [] in
test_expected_bound_variables pre_condition 2 &&
test_expected_disjoints pre_condition expected_disjoints ["fresh_var_1"; "fresh_var_2"]
(*
(* << false || emp >> free(x) << emp || x -> v >> *)
let%test "precondition on free(x), post-condition = << emp || x -> v >>" =
let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
let post_condition = 
  annot ( 
    PFormula.Or(
      annot (PFormula.EmptyHeap),
      annot (
        PFormula.Allocation(
        "x",
        annot (PArithmeticExpression.Variable("v"))
      ))
    )
  ) in
let post_condition = existential_disjuntive_normal_form post_condition in
let pre_condition = compute_precondition command post_condition in
let expected_disjoints = Formula.EmptyHeap :: Formula.False :: [] in
test_expected_bound_variables pre_condition 0 &&
test_expected_disjoints pre_condition expected_disjoints 

(* << false >> free(x) << emp && x -> v >> *)
let%test "precondition on free(x), post-condition = << emp && x -> v >>" =
let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
let post_condition = 
  annot ( 
    PFormula.And(
      annot (PFormula.EmptyHeap),
      annot (
        PFormula.Allocation(
        "x",
        annot (PArithmeticExpression.Variable("v"))
      ))
    )
  ) in
let post_condition = existential_disjuntive_normal_form post_condition in
let pre_condition = compute_precondition command post_condition in
let expected_disjoints = Formula.False :: [] in
test_expected_bound_variables pre_condition 0 &&
test_expected_disjoints pre_condition expected_disjoints 

(***************************** Frame Rule *********************************)

(* << emp * emp >> free(x) << emp * x -> v >> *)
let%test "precondition on free(x), post-condition = << emp * x -> v >>" =
let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
let post_condition = 
  annot ( 
    PFormula.AndSeparately(
      annot (PFormula.EmptyHeap),
      annot (
        PFormula.Allocation(
        "x",
        annot (PArithmeticExpression.Variable("v"))
      ))
    )
  ) in
let post_condition = existential_disjuntive_normal_form post_condition in
let pre_condition = compute_precondition command post_condition in
let expected_disjoints = Formula.AndSeparately( Formula.EmptyHeap, Formula.EmptyHeap ) :: [] in
test_expected_bound_variables pre_condition 0 &&
test_expected_disjoints pre_condition expected_disjoints 

(* << false >> free(x) << emp * y -> v >> *)
let%test "precondition on free(x), post-condition = << emp * y -> v >>" =
let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
let post_condition = 
  annot ( 
    PFormula.AndSeparately(
      annot (PFormula.EmptyHeap),
      annot (
        PFormula.Allocation(
        "y",
        annot (PArithmeticExpression.Variable("v"))
      ))
    )
  ) in
let post_condition = existential_disjuntive_normal_form post_condition in
let pre_condition = compute_precondition command post_condition in
let expected_disjoints = Formula.False :: [] in
test_expected_bound_variables pre_condition 0 &&
test_expected_disjoints pre_condition expected_disjoints 

(* << false >> free(x) << emp * x -/> >> *)
let%test "precondition on free(x), post-condition = << emp * y -/> >>" =
let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
let post_condition = 
  annot ( 
    PFormula.AndSeparately(
      annot (PFormula.EmptyHeap),
      annot (
        PFormula.NonAllocated("x")
      )
    )
  ) in
let post_condition = existential_disjuntive_normal_form post_condition in
let pre_condition = compute_precondition command post_condition in
let expected_disjoints = Formula.False :: [] in
test_expected_bound_variables pre_condition 0 &&
test_expected_disjoints pre_condition expected_disjoints 

(* << y -> v * emp >> free(x) << y -> v * x -> v >> *)
let%test "precondition on free(x), post-condition = << y -> v * x -> v >>" =
let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
let post_condition = 
  annot ( 
    PFormula.AndSeparately(
      annot (
        PFormula.Allocation(
        "y",
        annot (PArithmeticExpression.Variable("v"))
      )),
      annot (
        PFormula.Allocation(
        "x",
        annot (PArithmeticExpression.Variable("v"))
      ))
    )
  ) in
let post_condition = existential_disjuntive_normal_form post_condition in
let pre_condition = compute_precondition command post_condition in
let expected_disjoints = 
  Formula.AndSeparately(Formula.EmptyHeap, Formula.Allocation("y", Variable("v"))) :: [] 
in
test_expected_bound_variables pre_condition 0 &&
test_expected_disjoints pre_condition expected_disjoints 

(* << x -/> * emp >> free(x) << x -/> * x -> v >> *)
let%test "precondition on free(x), post-condition = << x -/> * x -> v >>" =
let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
let post_condition = 
  annot ( 
    PFormula.AndSeparately(
      annot (PFormula.NonAllocated("x")),
      annot (
        PFormula.Allocation(
        "x",
        annot (PArithmeticExpression.Variable("v"))
      ))
    )
  ) in
let post_condition = existential_disjuntive_normal_form post_condition in
let pre_condition = compute_precondition command post_condition in
let expected_disjoints = Formula.False :: [] in
test_expected_bound_variables pre_condition 0 &&
test_expected_disjoints pre_condition expected_disjoints 

(* << emp * true >> free(x) << emp * true >> *)
let%test "precondition on free(x), post-condition = << emp * true >>" =
let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
let post_condition = 
  annot ( 
    PFormula.AndSeparately(
      annot (PFormula.EmptyHeap),
      annot (PFormula.True)
    )
  ) in
let post_condition = existential_disjuntive_normal_form post_condition in
let pre_condition = compute_precondition command post_condition in
let expected_disjoints = 
  Formula.AndSeparately(Formula.EmptyHeap, Formula.True) :: [] 
in
test_expected_bound_variables pre_condition 0 &&
test_expected_disjoints pre_condition expected_disjoints 

(* << true * emp >> free(x) << true * x -> v >> *)
let%test "precondition on free(x), post-condition = << true * x -> v >>" =
let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
let post_condition = 
  annot ( 
    PFormula.AndSeparately(
      annot (PFormula.True),
      annot (
        PFormula.Allocation(
        "x",
        annot (PArithmeticExpression.Variable("v"))
      ))
    )
  ) in
let post_condition = existential_disjuntive_normal_form post_condition in
let pre_condition = compute_precondition command post_condition in
let expected_disjoints = 
  Formula.AndSeparately(Formula.EmptyHeap, Formula.True) :: [] in
test_expected_bound_variables pre_condition 0 &&
test_expected_disjoints pre_condition expected_disjoints 

(* << true * false >> free(x) << true * y -> v >> *)
let%test "precondition on free(x), post-condition = << true * y -> v >>" =
let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
let post_condition = 
  annot ( 
    PFormula.AndSeparately(
      annot (PFormula.True),
      annot (
        PFormula.Allocation(
        "y",
        annot (PArithmeticExpression.Variable("v"))
      ))
    )
  ) in
let post_condition = existential_disjuntive_normal_form post_condition in
let pre_condition = compute_precondition command post_condition in
let expected_disjoints = 
  Formula.AndSeparately(Formula.True, Formula.Allocation("y", Variable("v"))) :: [] in
test_expected_bound_variables pre_condition 0 &&
test_expected_disjoints pre_condition expected_disjoints 

(* << v = 5 * emp * y -> v >> free(x) << v = 5 * x -> v * y -> v >> *)
let%test "precondition on free(x), post-condition = << v = 5 * x -> v * y -> v >>" =
let command = annot_cmd (Commands.HeapAtomicCommand.Free("x")) in
let post_condition = 
  annot ( 
    PFormula.AndSeparately(
      annot (PFormula.Allocation("v", (annot (PArithmeticExpression.Literal(5) ) ) ) ),
      annot (PFormula.AndSeparately(
        annot (PFormula.Allocation("x", annot (PArithmeticExpression.Variable("v") ) ) ),
        annot (PFormula.Allocation("y", annot (PArithmeticExpression.Variable("v") ) ) ) 
      )
    ))
  ) in
let post_condition = existential_disjuntive_normal_form post_condition in
let pre_condition = compute_precondition command post_condition in
let expected_disjoints = 
  Formula.AndSeparately(
    Formula.EmptyHeap, 
    Formula.AndSeparately(
      Formula.Allocation("v", Literal(5)), 
      Formula.Allocation("y", Variable("v"))
    )
  ) :: [] in
test_expected_bound_variables pre_condition 0 &&
test_expected_disjoints pre_condition expected_disjoints 
*)