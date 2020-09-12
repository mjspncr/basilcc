# BasilCC, Basil Compiler Compiler

BasilCC is a backtracking LR parser generator. It produces a finite
state machine (FSM) given a context free grammar (CFG). The parser
loads the FSM at runtime and builds an abstract syntax tree (AST)
bottom-up as the CFG rules are reduced. Semantic actions, coded in
Lua, can introduce custom nodes in the AST and traverse built-in nodes
using the visitor pattern.

BasilCC generates default reductions to minimize the size _and_ number
of states in the FSM. Two states (with the same kernel rules) are
collapsed into one if both produce the same shift and reduce actions
over all possible lookahead tokens, and the same holds true
recursively over all pairwise state transitions. The FSM provides the
power of LR with minimum overhead.

The generated fsm right now is not interchangeably between 32/64 bits
we need to regenerate it for 32/64.

## Grammar File

BasilCC takes as input a grammar file containing rules and
directives. Anything to the right of a pound sign (#) is a comment.

A rule states that a symbol, a noterminal, can expand to zero or more
symbols. The nonterminal is on the left-hand side of an arrow, and the
symbols to which it can expand are on the right. A symbol with all
upper case letters is a token, a nonterminal otherwise.

For example here is a CFG accepting zero or more Ys followed by one Z.

```
start -> y-seq Z
y-seq ->
y-seq -> y-seq Y
```

A rule with the nonterminal 'start' on the left side is a start rule,
and it indicates a root in the CFG. The CFG must have at least one such
rule.

Attributes can follow a symbol and are used to assign lexical state,
resolve parsing conflicts, and mark accepting reductions. Attributes
influence the symbol in the context of the rule only. More on
attributes below.

An AST node type can be paired with a rule by following the left-hand
side symbol with an identifier in square brackets, after any
attributes. The identifier, normalized, is the type name. The
identifier is normalized by capitalizing the first letter of each
word, treating (then removing) the underscore and minus sign as word
delimiters.

If a node type is paired with a rule then an instance of the type, a
node, is created when the rule is reduced. The node's array (the node
is a Lua table) will contain a child node for each right-hand side
symbol. If you define an "onNode" method then it is called when the
rule is reduced, and the return value replaces the node. Unless the
rule is start rule, the node will represent the left-hand side symbol
as a child in a later reduction.

Here is a simple expression CFG. Five node types are 
introduced: AddExpr1, AddExpr2, MulExpr1, MulExpr2 and Factor.

```
start -> add-expr
add-expr [add-expr1] -> add-expr PLUS mul-expr
add-expr [add-expr2] -> add-expr MINUS mul-expr
add-expr-> mul-expr
mul-expr [mul-expr1] -> mul-expr TIMES factor
mul-expr [mul-expr2] -> mul-expr DIVIDE factor
mul-expr -> factor
factor [factor] -> NUMBER
```

A percent sign as the first non-whitespace character on a line starts
a directive. Unlike a rule, a directive cannot extend over one
line. There are two kinds of directives.

A _keyword_ directive states that a token is a keyword with the given
lexeme (or spelling). The list of lexemes -- each paired with a unique
token number -- is stored in the FSM, so they can be referenced by
your lexer. Here are a few examples:

```
%keyword CLASS "class"
%keyword INT "int"
%keyword NAMESPACE "namespace"
```

A _recover_ directive adds a recover strategy on syntax errors. The
parser can insert a token, or discard some number of
tokens. Here are a few examples:

```
%recover insert SEMI
%recover insert RBRACE
%recover discard 5
```

The strategies are stored in the FSM in the order they appear. At
runtime when the parser encounters a syntax error it will backtrack to
the last accepting state and attempt the strategies in order. If the
parser reaches an accepting state it recovers and continues, otherwise
it aborts with a syntax error.

## Attributes

### Lexical State

Every LR parser state has a lexical state. The lexical state is an
integer that is derived from all possible lookahead tokens. The parser
consumes tokens on demand, calling a function in the lexer when it
requires the next one. The current lexical state (the one associated
with the current LR parser state) is passed to the lexer on this call,
allowing the lexer to make context sensitive decisions when forming the
next token.

The lexical state assigned to a symbol, in its context only, transfers
to all tokens in the symbol's first set.

For example the CFG below will accept one of two token sequences, A B
C B or B C B. Assuming valid input, the lexical state on the first
call to the lexer (to get B or A) will be 1. The lexical state to get
the second B will be 2.

```
start -> a-opt b 1 C b 2
a-opt -> A
a-opt ->  
b -> B
```

BasilCC will report a lexical state conflict if there are competing
lexical states in the CFG. Here is an example:

```
start -> a-opt B 2
a-opt -> A 1
a-opt ->
```

Note when the parser backtracks it may discard some tokens. The parser
will cache those tokens and reuse them when advancing -- backtracking
does not extend to the lexer.

### Accept

Performing a backtracking LR parse is akin to searching a tree in
depth-first search order. A shift/reduce or a reduce/reduce conflict
introduces a branch in the tree. On a conflict the parser will try the
first action -- if that one results in a failed parse then the parser
will backtrack and try the other (the actions are ordered using the
priories described below).

An accepting reduction will cause the parser to cancel any pending
constructions of the rule's right-hand side. If, after the reduction,
there _no_ pending constructions then the reduction produces an
accepting state.

The accept attribute, *, is used to indicate an accepting reduction.

If the accept attribute is on a rule's left-hand side symbol then when
the rule is reduced it is an accepting reduction. Note the accept
property is not assigned to the rule. Instead, it is assigned to all
tokens in the rule's follow set. If a
token in a follow set has the accept property then it produces an
accepting reduction. This distinction is important when considering
the case of an accept attribute on a right-hand side nonterminal.
 
If the accept attribute is on a right-hand side nonterminal then all
tokens that follow it are assigned the accept property when they are
collected to form the follow set for rules with the same symbol on the
left-hand side.

It's a good idea to trigger accepting states even when the CFG has no
conflicts. When the parser encounters a syntax error it will backtrack
to the last accepting state. If there are no accepting states then the
parser will backtrack to the start and recover only if it can parse
the entire token stream successfully (after applying a recover
strategy).

It's also important to trigger an accepting state after performing
semantic actions that influence the program state.

Below is an example. The CFG accepts a sequence of declarations. To
keep it simple suppose a declaration can be A, B or C followed by a
semi-colon. If semantic actions add the declarations to the scope --
influencing the program state -- then you should indicate that all
three are accepting reductions.

```
start -> decl-seq
decl-seq -> decl-seq decl
decl-seq -> decl
decl -> any-decl SEMI
any-decl * [a-decl] -> A
any-decl * [b-decl] -> B
any-decl * [c-decl] -> C
```

### Sticky

Because BasilCC generates default reductions a rule may be reduced
when any token is next -- not only just the set of tokens that are
valid in that context. To prevent this use the sticky attribute, <.

If a sticky attribute is on a rule's left-hand side symbol then that
rule will be reduced only if a valid token is next. Like the accept
attribute, the sticky property is not assigned to the rule, instead it
is assigned to all tokens in the rule's follow set, and sticky tokens
are not considered when searching for the rule's default reduction.

If a sticky attribute is on a right-hand side nonterminal then all
tokens that follow it are assigned the sticky property when they are
collected to form the follow set for rules with the same symbol on the
left-hand side.

Consider the last example. The 3 rules with 'any-decl' on the left
hand side will be reduced when any token is next. To make sure the
reductions occur only when a SEMI is next use a sticky attribute:

```
start -> decl-seq
decl-seq -> decl-seq decl
decl-seq -> decl
decl -> any-decl *< SEMI
any-decl [a-decl] -> A
any-decl [b-decl] -> B
any-decl [c-decl] -> C
```

### Shift, Reduce and First Priority

The priority attributes are used to order the actions on shift/reduce and
reduce/reduce conflicts. The parser will try the actions on a conflict
in order, highest priority first. BasilCC will report an error if the
actions are not ordered.

First consider a shift/reduce conflict:

```
start -> a-opt A
a-opt -> A
a-opt ->
```

This CFG will accept one A or two As. To shift first give the optional
A a shift priority using the shift priority attribute, >:

```
start -> a-opt A
a-opt -> A >
a-opt ->
```
  
The attribute can also be used on the right-hand side:

```
start -> a-opt > A
a-opt -> A
a-opt ->
```

This results in same order, but here you're saying shift first in this
context only.

Consider:

```
start -> a-opt > A X a-opt + A
a-opt -> A
a-opt ->
```

Now 'a-opt' is used in two contexts, before and after an X. After the
X the 'a-opt' is given a reduce priority, +.  So after the X the parser
will reduce first.

The same can be done by using a first priority, ^, on the last A:

```
start -> a-opt > A X a-opt A ^
a-opt -> A
a-opt ->
```

Here's a more contrived example that shows when you might prefer to
use a first priority:

```
start -> a-or-b-opt > b-opt ^^ A
a-or-b-opt -> a-or-b
a-or-b-opt -> 
a-or-b -> A
a-or-b -> B
b-opt -> B
b-opt ->
```

Here the parser will shift first on A, but reduce first on B.

Note

* Priorities have reach (for the lack of a better word). Note
  'a-or-b-opt' is given a shift priority above -- this in turn gives
  'a-or-b' shift priority and this in turn gives both A and B shift
  priority. Priorities have unlimited reach.

* Priorities are additive. Note the 2 first priorities on 'b-opt'
  above. The shift priority on 'a-or-b-opt' gives the shift action on
  the optional B priority. So to reduce first you need to give the
  reduce action 2 priorities.

The same can be done using priorities on the tokens directly:

```
start -> a-or-b-opt b-opt A
a-or-b-opt -> a-or-b
a-or-b-opt -> 
a-or-b -> A >
a-or-b -> B
b-opt -> B ^
b-opt ->
```

Here 1 first priority on B is sufficient. Note that the
first priority on B influences the ordering of actions on the start
rule. First priorities have unlimited _reverse_ reach.

Here's another example:

```
start -> a
a -> b >
a -> c
b -> A x-opt B
c -> A y-opt B
x-opt -> T
x-opt ->
y-opt -> T
y-opt -> 
```

Note the conflict after shifting A. If B is next there's a
reduce/reduce conflict. If T is next there's another reduce/reduce
conflict after shifting it. But because 'b' is given a shift priority
both conflicts are ordered in favor of 'b'. This has real
applications. In C++ you favor a declaration over an
expression. Implementing this is simple:

```
stmt -> expr
stmt -> decl >
```

Finally, what if after ordering actions you want to ignore the ones
with the lower priority -- that is, you don't want the parser to
guess. A bang, !, after any priority drops any actions with lower
priority.

Here's an example:

```
start -> a-opt +! A
a-opt -> A
a-opt ->
```

Here the parser will always reduce, never backtrack. Again, this has
real applications. In C++ the greater-than sign in a template-id is
never a relational operator:

```
template-id -> name LT arg-seq GT ^!
```

The '>' in 'A<1>x' is always closing the template-id. Very simple
to implement.
