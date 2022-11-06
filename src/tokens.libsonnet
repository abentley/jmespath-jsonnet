{
  rawToken(name, content, remainder=null): {
    token: {
      name: name,
      content: content,
    },
    remainder: remainder,
  },

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
    else if expression[0] == '.' then self.subExpressionToken(expression)
    else if expression[0] == '|' then self.pipeToken(expression)
    else if std.member('=<>!', expression[0:1]) then
      self.comparatorToken(expression)
    else if expression[0] == "'" then self.rawStringToken(expression)
    else if expression[0] == '"' then self.idStringToken(expression)
    else if expression[0] == '`' then self.jsonLiteralToken(expression)
    else if expression[0] == '*' then self.objectWildcardToken(expression)
    else error 'Unhandled expression: %s' % std.manifestJson(expression),

  // Return an array of all tokens
  // Expression must be a string
  alltokens(expression, curTokens): (
    local rawToken = self.token(expression);
    local result =
      curTokens + [rawToken.token];
    assert rawToken != null : expression;
    if rawToken.remainder == null then result
    else self.alltokens(rawToken.remainder, result)
  ),

  idToken(expression, offset=0):
    local rawRemainder = expression[offset:];
    local remainder =
      if std.length(rawRemainder) == 0 then null else rawRemainder;
    if offset + 1 == std.length(expression) then
      self.rawToken('id', expression)
    else if self.idChar(expression[offset], first=false) then
      self.idToken(expression, offset + 1)
    else self.rawToken('id', expression[:offset], remainder),

  stringAdvance(expression, terminal, index):
    index + 1,

  advance(expression, terminal, index):
    local next = index + 1;
    if expression[index] == '"' then
      self.parseI(expression, '"', next, self.stringAdvance) + 1
    else if expression[index] == '`' then
      // This is a JSON string, so it can have single- and double- quotes in
      // it, with approximately the same meaning.
      self.parseI(expression, '`', next, self.advance) + 1
    else if expression[index] == "'" then
      self.parseI(expression, "'", next, self.stringAdvance) + 1
    else next,

  parseI(expression, terminal, index, advance):
    local next = std.trace(expression, advance(expression, terminal, index));
    if expression[index] == terminal then index
    else self.parseI(expression, terminal, next, advance),

  parseUntil(func, expression, terminal, advance):
    local end = self.parseI(expression, terminal, 0, advance);
    local remainder =
      if end + 1 == std.length(expression) then null else expression[end + 1:];
    local contents = expression[:end];
    self.rawToken(func(contents), contents, remainder),

  bracketToken(expression):
    self.parseUntil((
      function(contents)
        std.trace(contents, if contents[0:1] == '?' then 'filterProjection'
        else if std.member(contents, ':') then 'slice'
        else if contents == '' then 'flatten'
        else if contents == '*' then 'arrayWildcard'
        else 'index',)
    ), expression[1:], ']', self.advance),

  objectWildcardToken(expression):
    local rawRemainder = expression[1:];
    local remainder = if rawRemainder == '' then null else rawRemainder;
    self.rawToken('objectWildcard', expression[0], remainder),

  subExpressionToken(expression):
    self.rawToken('subexpression', expression[1:], null),

  pipeToken(expression):
    self.rawToken('pipe', expression[1:], null),

  comparatorToken(expression):
    self.rawToken('comparator', expression, null),

  rawStringToken(expression):
    self.parseUntil(
      function(x) 'rawString', expression[1:], "'", self.stringAdvance
    ),

  idStringToken(expression):
    self.parseUntil(
      function(x) 'idString', expression[1:], '"', self.stringAdvance
    ),

  jsonLiteralToken(expression):
    self.parseUntil(
      function(x) 'jsonLiteral', expression[1:], '`', self.advance
    ),
}
