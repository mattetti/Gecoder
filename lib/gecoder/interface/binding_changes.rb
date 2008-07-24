# This file adds a small layer on top of the bindings. It alters the allocation 
# of variables so that a single array is allocated in each space which is then 
# used to store variable. The variables themselves are not directly returned, 
# rather they are represented as the index in that store, which allows the 
# variable to be retrieved back given a space.
module GecodeRaw #:nodoc: all
  class Space
    # Used by Gecode during BAB-search.
    def constrain(best_so_far_space)
      Gecode::Model.constrain(self, best_so_far_space)
    end
    
    # Refreshes the underlying stores used by the space.
    def refresh
      # TODO remove
    end
  end
end
