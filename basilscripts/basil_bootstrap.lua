-- bootstrap grammar parser

local rule     = basil.rule
local symbol   = basil.symbol
local priority = basil.priority

rule{left_symbol='start', right_symbols={'rule-seq-opt'}}
rule{left_symbol='rule-seq-opt'}
rule{left_symbol='rule-seq-opt', right_symbols={'rule-seq'}}
rule{left_symbol='rule-seq', right_symbols={'rule'}}
rule{left_symbol='rule-seq', right_symbols={'rule-seq', 'rule'}}
rule{'rule', left_symbol='rule', right_symbols={symbol{'rule-name-opt', shift_priority=1}, 'symbol', 'ARROW', symbol{'symbol-seq-opt', shift_priority=1}}}
rule{left_symbol='rule-name-opt'}
rule{left_symbol='rule-name-opt', right_symbols={symbol{'rule-name', accept=true}}}
rule{'rule_name_1', left_symbol='rule-name', right_symbols={'IDENT', 'EQUALS'}}
rule{'rule_name_2', left_symbol='rule-name', right_symbols={'IDENT', 'COLON'}}
rule{left_symbol='symbol-seq-opt'}
rule{left_symbol='symbol-seq-opt', right_symbols={'symbol-seq'}}
rule{'symbol_seq_1', left_symbol='symbol-seq', right_symbols={'symbol'}}
rule{'symbol_seq_2', left_symbol='symbol-seq', right_symbols={'symbol-seq', 'symbol'}}
rule{'symbol', left_symbol=symbol{'symbol', sticky=true, accept=true}, right_symbols={'IDENT', 'attrib-seq'}}
rule{'attrib_seq_1', left_symbol='attrib-seq'}
rule{'attrib_seq_2', left_symbol='attrib-seq', right_symbols={'attrib-seq', 'NUMBER'}}
rule{'attrib_seq_3', left_symbol='attrib-seq', right_symbols={'attrib-seq', 'LT'}}
rule{'attrib_seq_4', left_symbol='attrib-seq', right_symbols={'attrib-seq', 'STAR'}}
rule{'attrib_seq_5', left_symbol='attrib-seq', right_symbols={'attrib-seq', 'PLUS', 'bang-seq-opt'}}
rule{'attrib_seq_6', left_symbol='attrib-seq', right_symbols={'attrib-seq', 'CARET', 'bang-seq-opt'}}
rule{'attrib_seq_7', left_symbol='attrib-seq', right_symbols={'attrib-seq', 'GT', 'bang-seq-opt'}}
rule{left_symbol='bang-seq-opt'}
rule{left_symbol='bang-seq-opt', right_symbols={'bang-seq'}}
rule{'bang_seq_1', left_symbol='bang-seq', right_symbols={'BANG'}}
rule{'bang_seq_2', left_symbol='bang-seq', right_symbols={'bang-seq', 'BANG'}}
