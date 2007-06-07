# Copyright (c) 2007 David Cuadrado <krawek@gmail.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'set'
require 'rust/element'
require 'rust/type'

module Rust
  class Attribute < Element
    def initialize(name, type, opts)
      super()
      
      @name = name
      @type = Type.new(type)
      @options = opts
      
      @declaration_template = ""
      @definition_template = Templates["AttributeDefinition"]
      @prototype_template = "void set!attribute_bindname!(VALUE self, VALUE val);\nVALUE get!attribute_bindname!(VALUE self);\n"
      @initialization_template = Templates["AttributeInitBinding"]
      
      
      add_expansion 'parent_varname', "@options[:parent].varname"
      add_expansion 'attribute_bindname', "@name"
      add_expansion 'attribute_type', "@type"
      add_expansion 'attribute_name', "@name"
    end
    
  end
end


