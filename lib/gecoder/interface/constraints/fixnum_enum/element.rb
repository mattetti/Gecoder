module Gecode::Constraints::FixnumEnum
  module FixnumEnumOperand
    # This adds the adder for the methods in the modules including it. The 
    # reason for doing it so indirect is that the first #[] won't be defined 
    # before the module that this is mixed into is mixed into an enum.
    def self.included(enum_mod)
      enum_mod.module_eval do
        # Now we enter the module FixnumEnumOperands is mixed into.
        class << self
          alias_method :pre_element_included, :included
          def included(mod)
            mod.module_eval do
              if instance_methods.include? '[]'
                alias_method :pre_element_access, :[]
              end
          
              # Produces an integer variable operand representing the
              # i:th constant integer in the enumeration, where i is the
              # value of the integer variable used as index. Think of it
              # as array access in the world of constraint programming.
              # 
              # == Example
              # 
              #   # The price of +selected_item+ as described by +prices+ .
              #   prices = wrap_enum([500, 24, 4711, 412, 24])
              #   prices[selected_item]
              # 
              def [](*vars)
                if vars.first.respond_to? :to_int_var
                  return Element::ElementIntVarOperand.new(
                    self, vars.first, model)
                else
                  pre_element_access(*vars) if respond_to? :pre_element_access
                end
              end
            end
            pre_element_included(mod)
          end
        end
      end
    end
  end

  module Element #:nodoc:
    class ElementIntVarOperand < Gecode::Constraints::Int::ShortCircuitEqualityOperand #:nodoc:
      def initialize(enum_op, position_int_var_op, model)
        super model
        @enum = enum_op
        @position = position_int_var_op
      end

      def constrain_equal(int_operand, constrain, propagation_options)
        if constrain
          int_operand.must_be.in @enum
        end

        Gecode::Raw::element(@model.active_space, @enum, 
          @position.to_int_var.bind, int_operand.to_int_var.bind, 
          *propagation_options)
      end
    end
  end
end
