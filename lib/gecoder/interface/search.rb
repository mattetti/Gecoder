module Gecode
  class Model
    # Finds the first solution to the modelled problem and updates the variables
    # to that solution. Returns the model if a solution was found, nil 
    # otherwise.
    def solve!
      space = dfs_engine.next
      return nil if space.nil?
      @active_space = space
      return self
    end
    
    # Returns to the original state, before any search was made (but propagation 
    # might have been performed). Returns the reset model.
    def reset!
      @active_space = base_space
      return self
    end
    
    # Yields the first solution (if any) to the block. If no solution is found
    # then the block is not used. Returns the result of the block (nil in case
    # the block wasn't run). 
    def solution(&block)
      solution = self.solve!
      res = yield solution unless solution.nil?
      self.reset!
      return res
    end
    
    # Yields each solution that the model has.
    def each_solution(&block)
      dfs = dfs_engine
      while not (@active_space = dfs.next).nil?
        yield self
      end
      self.reset!
    end
    
    # Finds the optimal solution. Optimality is defined by the provided block
    # which is given one parameter, a solution to the problem. The block should
    # constrain the solution so that that only "better" solutions can be new 
    # solutions. For instance if one wants to optimize a variable named price
    # (accessible from the model) to be as low as possible then one should write
    # the following.
    #
    # model.optimize! do |solution|
    #   solution.price.must < solution.price.val
    # end
    #
    # Return nil if there is no solution.
    def optimize!(&block)
      # A method named constrain has to be defined: http://www.gecode.org/gecode-doc-latest/bab_8icc-source.html
      space = nil
      solution_found = false
      while !(space = bab_engine.next).nil?
        solution_found = true
        @active_space = space
        block.call(self)
        @active_space = @base_space
      end
      if solution_found
        @active_space = space
        return self
      else
        return nil
      end
    end
    
    private
    
    # Creates a depth first search engine for search, executing any 
    # unexecuted constraints first.
    def dfs_engine
      # Execute constraints.
      execute_constraints
      
      # Construct the engine.
      stop = Gecode::Raw::Search::Stop.new
      Gecode::Raw::DFS.new(active_space, 
        Gecode::Raw::Search::Config::MINIMAL_DISTANCE,
        Gecode::Raw::Search::Config::ADAPTIVE_DISTANCE, 
        stop)
    end
    
    # Creates a branch and bound engine for optimization search, executing any 
    # unexecuted constraints first.
    def bab_engine
      # Execute constraints.
      execute_constraints
      
      # Construct the engine.
      stop = Gecode::Raw::Search::Stop.new
      Gecode::Raw::BAB.new(active_space, 
        Gecode::Raw::Search::Config::MINIMAL_DISTANCE,
        Gecode::Raw::Search::Config::ADAPTIVE_DISTANCE, 
        stop)
    end
    
    # Executes any unexecuted constraints waiting in the queue (emptying the
    # queue).
    def execute_constraints
      constraints.each{ |con| con.post }
      constraints.clear # Empty the queue.
    end
  end
end
