require('basilcc.parser_actions')

-- on syntax error discard up to 5 tokens
basil.recover_policies {
  {basil.RECOVER_DISCARD; 5}
}
