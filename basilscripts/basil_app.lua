-- basil parser semantic actions

local nodes    = require 'basil_nodes'

local rule     = basil.rule
local name     = basil.name
local symbol   = basil.symbol
local priority = basil.priority

-- rule-name -> IDENT EQUALS
function nodes.RuleName1:onNode()
   local IDENT = self[1]
   return name{IDENT.lexeme, loc=IDENT.loc, is_node=true}
end

-- rule-name -> IDENT COLON
function nodes.RuleName2:onNode()
   local IDENT = self[1]
   return name{IDENT.lexeme, loc=IDENT.loc}
end

-- attrib-seq < ->
function nodes.AttribSeq1:onNode()
   return {}
end

-- attrib-seq -> attrib-seq NUMBER
function nodes.AttribSeq2:onNode()
   local attribs = self[1]
   attribs.lex_state = tonumber(self[2].lexeme)
   return attribs
end

-- attrib-seq -> attrib-seq LT
function nodes.AttribSeq3:onNode()
   local attribs = self[1]
   attribs.sticky = true
   return attribs
end

-- attrib-seq -> attrib-seq STAR
function nodes.AttribSeq4:onNode()
   local attribs = self[1]
   attribs.accept = true
   return attribs
end

-- attrib-seq -> attrib-seq PLUS  bang-seq-opt
function nodes.AttribSeq5:onNode()
   local attribs = self[1]
   attribs.reduce_priority = attribs.reduce_priority + priority{1, bang=self[3]}
   return attribs
end

-- attrib-seq -> attrib-seq CARET bang-seq-opt
function nodes.AttribSeq6:onNode()
   local attribs = self[1]
   attribs.first_priority = attribs.first_priority + priority{1, bang=self[3]}
   return attribs
end

-- attrib-seq -> attrib-seq GT    bang-seq-opt
function nodes.AttribSeq7:onNode()
   local attribs = self[1]
   attribs.shift_priority = attribs.shift_priority + priority{1, bang=self[3]}
   return attribs
end

-- symbol -> IDENT attrib-seq
function nodes.Symbol:onNode()
   local IDENT = self[1]
   local attribs = self[2]
   return symbol{IDENT.lexeme, loc=IDENT.loc, reduce_priority=attribs.reduce_priority, first_priority=attribs.first_priority,
      shift_priority=attribs.shift_priority, lex_state=attribs.lex_state, sticky=attribs.sticky, accept=attribs.accept}
end

-- get symbols visitor
local GetSymbols = {}
-- symbol-seq < -> symbol
function GetSymbols:onSymbolSeq1(node)
   return {node[1]}
end
-- symbol-seq < -> symbol-seq symbol
function GetSymbols:onSymbolSeq2(node)
   local symbols = node[1]:accept(self)
   table.insert(symbols, node[2])
   return symbols
end

-- rule <* -> rule-name-opt symbol ARROW symbol-seq-opt >
function nodes.Rule:onNode()
   local right_symbols
   if self[4] then
      right_symbols = self[4]:accept(GetSymbols)
   end
   rule{self[1], left_symbol=self[2], right_symbols=right_symbols}
end

-- bang-seq -> BANG
function nodes.BangSeq1:onNode()
   return 1
end

-- bang-seq -> bang-seq BANG
function nodes.BangSeq2:onNode()
   return self[1] + 1
end
