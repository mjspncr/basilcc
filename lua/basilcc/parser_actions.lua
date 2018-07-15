-- basil parser semantic actions

local fsm = require('basilcc.parser_fsm')

-- node-type -> LBRACK IDENT RBRACK
function fsm.NodeType:onNode()
   -- return node name
   return self[2].lexeme
end

-- bang-seq -> BANG
function fsm.BangSeq1:onNode()
   -- return number of !s
   return 1
end

-- bang-seq -> bang-seq BANG
function fsm.BangSeq2:onNode()
   -- return number of !s
   return self[1] + 1
end

-- attrib-seq visitor, collects attributes
GetAttributes = {}
GetAttributes.__index = GetAttributes
-- attrib-seq ->
function GetAttributes:onAttribSeq1(node)
   -- return just a table with attributes, no longer a visitor
   return setmetatable(self, nil)
end
-- attrib-seq -> attrib-seq NUMBER
function GetAttributes:onAttribSeq2(node)
   self.number = tonumber(node[2].lexeme)
   return node[1]:accept(self)
end
-- attrib-seq -> attrib-seq LT
function GetAttributes:onAttribSeq3(node)
   self.sticky = true
   return node[1]:accept(self)
end
-- attrib-seq -> attrib-seq STAR
function GetAttributes:onAttribSeq4(node)
   self.accept = true
   return node[1]:accept(self)
end
-- attrib-seq -> attrib-seq PLUS bang-seq-opt
function GetAttributes:onAttribSeq5(node)
   self.reduce_priority = self.reduce_priority + basilcc.priority{1, bang=node[3]}
   return node[1]:accept(self)
end
-- attrib-seq -> attrib-seq CARET bang-seq-opt
function GetAttributes:onAttribSeq6(node)
   self.first_priority  = self.first_priority  + basilcc.priority{1, bang=node[3]}
   return node[1]:accept(self)
end
-- attrib-seq -> attrib-seq GT    bang-seq-opt
function GetAttributes:onAttribSeq7(node)
   self.shift_priority  = self.shift_priority  + basilcc.priority{1, bang=node[3]}
   return node[1]:accept(self)
end

-- symbol -> IDENT attrib-seq
function fsm.Symbol:get_symbol()
   local attributes = self[2]:accept(setmetatable({}, GetAttributes))
   return basilcc.symbol {
      self[1].lexeme;
      loc = self[1].loc,
      reduce_priority = attributes.reduce_priority,
      first_priority = attributes.first_priority,
      shift_priority = attributes.shift_priority,
      lex_state = attributes.lex_state,
      sticky = attributes.sticky,
      accept = attributes.accept
   }
end

-- get symbols from symbol-seq
GetSymbolSequence = {}
GetSymbolSequence.__index = GetSymbolSequence
-- symbol-seq -> symbol
function GetSymbolSequence:onSymbolSeq1(node)
   table.insert(self, node[1]:get_symbol())
end
-- symbol-seq -> symbol-seq symbol
function GetSymbolSequence:onSymbolSeq2(node)
   node[1]:accept(self)
   table.insert(self, node[2]:get_symbol())
end

-- rule -> symbol node-type-opt ARROW symbol-seq-opt
function fsm.Rule:onNode()
   local right_hand_side
   if self[4] then
      right_hand_side = setmetatable({}, GetSymbolSequence)
      self[4]:accept(right_hand_side)
   end
   basilcc.add_rule {
      self[1]:get_symbol();
      name = self[2],
      right_hand_side = right_hand_side
   }
end

-- rule -> IDENT COLON symbol ARROW symbol-seq-opt
function fsm.RuleDeprecated:onNode()
   local right_hand_side
   if self[5] then
      right_hand_side = setmetatable({}, GetSymbolSequence)
      self[5]:accept(right_hand_side)
   end
   basilcc.add_rule {
      self[3]:get_symbol(),
      name = self[1].lexeme,
      right_hand_side = right_hand_side
   }
end
