{
  rawToken(name, content, remainder=null): {
    token: {
      name: name,
      content: content,
    },
    remainder: if remainder == '' then null else remainder,
  },
  indexRawToken(name, expression, end):
    local next = end + 1;
    local contents = expression[:end];
    self.rawToken(name, contents, expression[next:]),

  // Return true if a character is in the supplied range (false otherwise)
  between(char, lowest, highest):
    std.codepoint(char) >= std.codepoint(lowest)
    && std.codepoint(char) <= std.codepoint(highest),

  // Return true if the character can be part of an unquoted identifier.
  // first: if true, this would be the first character of the identifier
  idChar(char, first): (
    self.between(char, 'a', 'z') ||
    self.between(char, 'A', 'Z') || (
      if first then false else self.between(char, '0', '9')
    )
  ),

  // Return a token name, text, and remainder
  // Note: the returned text may omit some unneded syntax
  token(expression):
    if self.idChar(expression[0], first=true) then self.idToken(expression)
    else if expression[0] == '[' then self.bracketToken(expression)
    else if expression[0] == '.' then
      self.rawToken('subexpression', expression[1:], null)
    else if expression[0] == '|' then
      self.rawToken('pipe', expression[1:], null)
    else if std.member('=<>!', expression[0:1]) then
      self.rawToken('comparator', expression, null)
    else if expression[0] == "'" then
      self.rawEndToken('rawString', expression, self.parseRawString)
    else if expression[0] == '"' then
      self.rawEndToken('idString', expression, self.parseIdentifierString)
    else if expression[0] == '`' then
      self.rawEndToken('jsonLiteral', expression, self.parseJsonString)
    else if expression[0] == '*' then
      self.indexRawToken('objectWildcard', expression, 0)
    else error 'Unhandled expression: %s' % std.manifestJson(expression),

  // Return an array of all tokens
  // Expression must be a string
  alltokens(expression, curTokens): (
    local rawToken = self.token(expression);
    local result = curTokens + [rawToken.token];
    assert rawToken != null : expression;
    if rawToken.remainder == null then result
    else self.alltokens(rawToken.remainder, result)
  ),

  idToken(expression, offset=0):
    if offset + 1 == std.length(expression) then
      self.rawToken('id', expression)
    else if self.idChar(expression[offset], first=false) then
      self.idToken(expression, offset + 1)
    else self.rawToken('id', expression[:offset], expression[offset:]),

  stringAdvance(expression, index): index + 1,

  advance(expression, index):
    local next = index + 1;
    if expression[index] == '"' then
      self.parseIdentifierString(expression, next) + 1
    else if expression[index] == '`' then
      self.parseJsonString(expression, next) + 1
    else if expression[index] == "'" then
      self.parseRawString(expression, next) + 1
    else next,

  parseIdentifierString(expression, index):
    self.parseUntil(expression, '"', index, self.stringAdvance),

  parseRawString(expression, index):
    self.parseUntil(expression, "'", index, self.stringAdvance),

  parseJsonString(expression, index):
    // This is a JSON string, so it can have single- and double- quotes in
    // it, with approximately the same meaning.
    self.parseUntil(expression, '`', index, self.advance),

  parseUntil(expression, terminal, index, advance):
    // return the index of the ending character in the expression
    // terminal: The character that ends the token
    // advance: A function to advance the index to the next candidate.
    //  This is designed to support states, such as skipping forward in strings.
    //  See advance and stringAdvance.
    local next = advance(expression, index);
    if expression[index] == terminal then index
    else self.parseUntil(expression, terminal, next, advance),

  bracketToken(expression):
    // Name is deferred until contents are determined.
    local subExpression = expression[1:];
    local end = self.parseUntil(subExpression, ']', 0, self.advance);
    local contents = subExpression[:end];
    local name =
      if contents[0:1] == '?' then 'filterProjection'
      else if std.member(contents, ':') then 'slice'
      else if contents == '' then 'flatten'
      else if contents == '*' then 'arrayWildcard'
      else 'index';
    self.indexRawToken(name, subExpression, end),

  rawEndToken(name, expression, parseUntil):
    local subExpression = expression[1:];
    self.indexRawToken(name, subExpression, parseUntil(subExpression, 0)),
}
