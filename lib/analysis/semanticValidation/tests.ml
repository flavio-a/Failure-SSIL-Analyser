open Analysis_SemanticValidation_Base
open DataStructures.Parser.Commands

open Analysis_TestCommon

let%test "illegal read" =
  let ast = annot_cmd (HeapRegularCommand.Command(
    annot_cmd (HeapAtomicCommand.ReadHeap(
      "x", "x"
    ))
  ))
  in
  not (validate_ast ast)

  let%test "legal read" =
  let ast = annot_cmd (HeapRegularCommand.Command(
    annot_cmd (HeapAtomicCommand.ReadHeap(
      "x", "y"
    ))
  ))
  in
  validate_ast ast

let%test "illegal write" =
  let ast = annot_cmd (HeapRegularCommand.Command(
    annot_cmd (HeapAtomicCommand.WriteHeap(
      "x", annot_cmd (
        ArithmeticExpression.Variable("x")
      )
    ))
  ))
  in
  not (validate_ast ast)

let%test "legal write" =
  let ast = annot_cmd (HeapRegularCommand.Command(
    annot_cmd (HeapAtomicCommand.WriteHeap(
      "x", annot_cmd (
        ArithmeticExpression.Variable("y")
      )
    ))
  ))
  in
  validate_ast ast

let%test "sequencing" =
  let ast = annot_cmd (HeapRegularCommand.Sequence(
    annot_cmd (HeapRegularCommand.Command(
      annot_cmd (HeapAtomicCommand.WriteHeap(
        "x", annot_cmd (
          ArithmeticExpression.Variable("y")
        )
      ))
    )),
    annot_cmd (HeapRegularCommand.Command(
      annot_cmd (HeapAtomicCommand.Assignment(
        "y", annot_cmd (
          ArithmeticExpression.Variable("z")
        )
      ))
    ))
  ))
  in
  validate_ast ast
  
let%test "non deterministic fail" =
  let ast = annot_cmd (HeapRegularCommand.NondeterministicChoice(
    annot_cmd (HeapRegularCommand.Command(
      annot_cmd (HeapAtomicCommand.WriteHeap(
        "x", annot_cmd (
          ArithmeticExpression.Variable("x")
        )
      ))
    )),
    annot_cmd (HeapRegularCommand.Command(
      annot_cmd (HeapAtomicCommand.Assignment(
        "y", annot_cmd (
          ArithmeticExpression.Variable("z")
        )
      ))
    ))
  ))
  in
  not (validate_ast ast)

let%test "illegal star" =
  let ast = annot_cmd (HeapRegularCommand.Star(
    annot_cmd (HeapRegularCommand.Command(
      annot_cmd (HeapAtomicCommand.WriteHeap(
        "x", annot_cmd (
          ArithmeticExpression.Variable("x")
        )
      ))
    ))
  ))
  in
  not (validate_ast ast)