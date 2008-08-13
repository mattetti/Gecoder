module Gecode::Constraints::Bool
  class BoolVarConstraintReceiver
    # Provides commutivity with IntVarReceiver#==
    provide_commutativity(:==){ |rhs, _| rhs.respond_to? :to_int_var }
    alias_comparison_methods
  end
end
