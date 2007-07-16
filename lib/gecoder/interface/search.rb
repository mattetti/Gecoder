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
      next_space = nil
      best_space = nil
      bab = bab_engine
      
      Model.constrain_proc = lambda do |home_space, best_space|
#Gecode::Raw::rel(home_space, @z.bind, Gecode::Raw::IRT_GR, 10, Gecode::Raw::ICL_DEF)
        # TODO: The spaces are involved in the binding, and constraints depend
        # on which space the variables are bound to. Hence no binding and no
        # posting of constraints should ever be done outside a constraint's post
        # method. This is currently not followed by all constraints, that has to
        # be fixed.
        @active_space = best_space
        yield(self)
        @active_space = home_space
        execute_constraints
      end
      
      while !(next_space = bab.next).nil?
        best_space = next_space
      end
      return nil if best_space.nil?
      @active_space = best_space
      return self
    end
    
    class <<self
      def constrain_proc=(proc)
        @constrain_proc = proc
      end
    
      def constrain(home, best)
        if @constrain_proc.nil?
          raise NotImplementedError, 'Constrain method not implemented.' 
        else
          @constrain_proc.call(home, best)
        end
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
      Gecode::Raw::DFS.new(selected_space, 
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
      Gecode::Raw::BAB.new(selected_space, 
        Gecode::Raw::Search::Config::MINIMAL_DISTANCE,
        Gecode::Raw::Search::Config::ADAPTIVE_DISTANCE, 
        stop)
    end
    
    # Posts any postables still waiting in the queue (emptying the queue).
    def post_all_postables
      allow_space_access do
        space_postables.each{ |con| con.post }
        space_postables.clear # Empty the queue.
      end
    end
  end
end
