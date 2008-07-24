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

#include "gecoder.h"
#include "gecode.hh"

#include <iostream>
#include <map>

namespace Gecode {
  MSpace::MSpace() {
  }

  MSpace::MSpace(bool share, MSpace& s) : Gecode::Space(share, s) {
    int_variables.update(this, share, s.int_variables);
  }

  MSpace::~MSpace() {
#ifdef DEBUG
    fprintf(stderr, "gecoder: destructing MSpace %p\n", this);
#endif
  }

  Gecode::Space* MSpace::copy(bool share) {
    return new MSpace(share, *this);
  }

  /*
   * Creates a number of new integer variables with the specified
   * domain and returns their identifiers (which can then be
   * used to access the integer variables themselves via int_var()).
   * It's the caller's responsibility to free the memory allocated 
   * for the returned array.
   */
  int MSpace::new_int_var(int min, int max) {
    int id = int_variables.size();
    Gecode::IntVar* var = new IntVar(this, min, max);
    int_variables.add(this, *var);
    return id;
  }
  int MSpace::new_int_var(IntSet domain) {
    int id = int_variables.size();
    Gecode::IntVar* var = new IntVar(this, domain);
    int_variables.add(this, *var);
    return id;
  }

  /*
   * Fetches the integer variable with the specified identifier.
   */
  Gecode::IntVar* MSpace::int_var(int id) {
    return &int_variables[id];
  }

  void MSpace::gc_mark() {
    for(int i = 0; i < int_variables.size(); i++) {
      rb_gc_mark(Rust_gecode::cxx2ruby(&int_variables[i], false, false));
    }
  }

  // For BAB.
  void MSpace::constrain(MSpace* s) {
    // Call Ruby's constrain.
    rb_funcall(Rust_gecode::cxx2ruby(this), rb_intern("constrain"), 1,
        Rust_gecode::cxx2ruby(s, false)); 
  }

  /* 
   * MDFS is the same as DFS but with the size of a space inferred from the
   * other arguments, since it can't be done from the Ruby side.
   */
  MDFS::MDFS(MSpace* space, unsigned int c_d, unsigned int a_d, Search::Stop* st) : Gecode::Search::DFS(space, c_d, a_d, st, sizeof(space)) {
  }

  MDFS::~MDFS() {
  }

  /* 
   * MBAB is the same as BAB but with the size of a space inferred from the
   * other arguments, since it can't be done from the Ruby side.
   */
  MBAB::MBAB(MSpace* space, const Search::Options &o) : Gecode::BAB<MSpace>(space, o) {
  }

  MBAB::~MBAB() {
  }

  namespace Search {
    /* 
     * MStop combines the time stop and fail stop, but for what reason?
     * TODO: Try removing MStop, replacing it with plain Stop objects.
     */

    struct MStop::Private {
      Gecode::Search::TimeStop* ts;
      Gecode::Search::FailStop* fs;
    };

    MStop::MStop() : d(new Private) {
      d->ts = 0;
      d->fs = 0;
    }

    MStop::MStop(int fails, int time) : d(new Private) {
      d->ts = new Search::TimeStop(time);
      d->fs = new Search::FailStop(fails);
    }

    MStop::~MStop() {
    }

    bool MStop::stop(const Gecode::Search::Statistics &s) {
      if (!d->fs && !d->ts) return false;
      return d->fs->stop(s) || d->ts->stop(s);
    }

    Gecode::Search::Stop* MStop::create(int fails, int time) {
      if (fails < 0 && time < 0) return 0;
      if (fails < 0) return new Search::TimeStop(time);
      if (time  < 0) return new Search::FailStop(fails);

      return new MStop(fails, time);
    }
  }
}
