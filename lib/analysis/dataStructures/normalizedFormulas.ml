open Analysis_DataStructures_Base

(** Normalized Logic Formulas

Logic formulas are normalized in Existential Disjunctive Normal Form, which easens the implementation of the analysis.
A normalized formula consists in:
- A set of existentialized identifiers.
- A list of disjoint formulas. Each disjoint is a formula composed only of atomic propositions, conjunctions and separate conjunctions.
*)
module NormalForm = struct
  module BinaryOperator = struct include Ast.AnnotationLogic.BinaryOperator end

  module ArithmeticExpression = struct
    type t =
      | Literal of int
      | Variable of identifier
      | Operation of BinaryOperator.t * t * t
    [@@deriving show]
  end

  module BinaryComparison = struct include Ast.AnnotationLogic.BinaryComparison end

  module Formula = struct
    type t =
      | True
      | False
      | And of t * t
      | Comparison of BinaryComparison.t * ArithmeticExpression.t * ArithmeticExpression.t
      | EmptyHeap
      | NonAllocated of identifier
      | Allocation of identifier * ArithmeticExpression.t
      | AndSeparately of t * t
    [@@deriving show]
  end

  (** The id_generator data structure is used to keep track of variable renamings.
  It is an implementation detail and thus should not be visible outside. *)
  type id_generator = {
    first_id: int;
    last_id: int;
  }

  type t = {
    variables: IdentifierSet.t; [@opaque]
    disjoints: Formula.t list;
    id_generator: id_generator; [@opaque]
  }
  [@@deriving show]

  let make variables disjoints id_generator =
    {variables; disjoints; id_generator}
end