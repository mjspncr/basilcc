# BasilCC, Basil Compiler Compiler

BasilCC is a backtracking LR parser generator. It produces a finite
state machine (FSM) given a context free grammar (CFG). The parser
loads the FSM at runtime and builds an abstract syntax tree (AST)
bottom-up as the CFG rules are reduced. Semantic actions, coded in
Lua, can introduce custom nodes in the AST and traverse built-in nodes
using the visitor pattern.

BasilCC uses default reductions to minimize the size _and_ number of
states in the FSM. Two states (with the same kernel rules) are
collapsed into one if both produce the same shift and reduce actions
over all possible lookahead tokens, and the same holds true recursively
over all pairwise state transitions. The FSM provides the power of LR
with minimum overhead.
