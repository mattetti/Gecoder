/**
 * Gecode/R, a Ruby interface to Gecode.
 * Copyright (C) 2007 The Gecode/R development team.
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 **/

#ifndef __GECODER_H
#define __GECODER_H

#include <ruby.h>

#include <gecode/kernel.hh>
#include <gecode/int.hh>
#include <gecode/search.hh>
#include <gecode/minimodel.hh>
#include <gecode/set.hh>

#include "vararray.h"

namespace Gecode {
  class MPointerArray {
    public:
      MPointerArray(int initial_capacity = 10);
      ~MPointerArray();

      void* at(int i);
      void add(void* pointer);
      int size();
      int capacity();

    private:
      void** arr;
      int allocated_size;
      int next_index;
  };

  class MSpace : public Space {
    public:
      MSpace();
      explicit MSpace(MSpace& s, bool share=true);
      ~MSpace();
      Gecode::Space *copy(bool share);

      int new_int_var(int min, int max);
      int new_int_var(IntSet domain);
      Gecode::IntVar* int_var(int id);

      void gc_mark();

      void constrain(MSpace* s);

    private:
      MPointerArray* int_variables;
  };
  
  class MDFS : public Gecode::Search::DFS {
    public:
      MDFS(MSpace *space, unsigned int c_d, unsigned int a_d, Search::Stop* st = 0);
      ~MDFS();
  };

  class MBAB : public Gecode::BAB<MSpace> {
    public:
      MBAB(MSpace* space, const Search::Options &o);
      ~MBAB();
  };

  namespace Search {
    class MStop : public Gecode::Search::Stop {
      private:
        MStop(int fails, int time);

      public:
        MStop();
        ~MStop();

        bool stop (const Gecode::Search::Statistics &s);
        static Gecode::Search::Stop* create(int fails, int time);

      private:
        struct Private;
        Private *const d;
    };
  }
}

#endif


