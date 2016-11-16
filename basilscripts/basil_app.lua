-- basil parser semantic actions

local nodes = require 'basil_nodes'

-- rule-name -> IDENT EQUALS
function nodes.RuleName:onNode()
   return self[1].lexeme
end

-- attrib-seq < ->
function nodes.AttribSeq1:onNode()
   return {}
end

-- attrib-seq -> attrib-seq NUMBER
function nodes.AttribSeq2:onNode()
   self[1].lex_state = tonumber(self[2].lexeme)
   return self[1]
end

-- attrib-seq -> attrib-seq LT
function nodes.AttribSeq3:onNode()
   self[1].sticky = true
   return self[1]
end

-- attrib-seq -> attrib-seq STAR
function nodes.AttribSeq4:onNode()
   self[1].accept = true
   return self[1]
end

-- attrib-seq -> attrib-seq PLUS  bang-seq-opt
function nodes.AttribSeq5:onNode()
   self[1].reduce_priority = self[1].reduce_priority + basil.priority{1, bang=self[3]}
   return self[1]
end

-- attrib-seq -> attrib-seq CARET bang-seq-opt
function nodes.AttribSeq6:onNode()
   self[1].first_priority = self[1].first_priority + basil.priority{1, bang=self[3]}
   return self[1]
end

-- attrib-seq -> attrib-seq GT    bang-seq-opt
function nodes.AttribSeq7:onNode()
   self[1].shift_priority = self[1].shift_priority + basil.priority{1, bang=self[3]}
   return self[1]
end

-- symbol -> IDENT attrib-seq
function nodes.Symbol:onNode()
   local IDENT = self[1]
   local attribs = self[2]
   return basil.symbol{IDENT.lexeme, loc=IDENT.loc, reduce_priority=attribs.reduce_priority, first_priority=attribs.first_priority,
      shift_priority=attribs.shift_priority, lex_state=attribs.lex_state, sticky=attribs.sticky, accept=attribs.accept}
end

-- symbol-seq -> symbol
function nodes.SymbolSeq1:onNode()
   return {self[1]}
end

-- symbol-seq -> symbol-seq symbol
function nodes.SymbolSeq2:onNode()
   table.insert(self[1], self[2])
   return self[1]
end

-- rule <* -> rule-name-opt symbol ARROW symbol-seq-opt >
function nodes.Rule:onNode()
   basil.rule{self[1], left_symbol=self[2], right_symbols=self[4]}
end

-- bang-seq -> BANG
function nodes.BangSeq1:onNode()
   return 1
end

-- bang-seq -> bang-seq BANG
function nodes.BangSeq2:onNode()
   return self[1] + 1
end
