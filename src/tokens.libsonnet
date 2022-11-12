/*
Copyright 2022 Aaron Bentley

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
{
  rawToken(name, content, remainder=null): {
    token: {
      name: name,
      content: content,
    },
    remainder: if remainder == '' then null else remainder,
  },
  indexRawToken(name, expression, end, next=null):
    local realNext = if next == null then end + 1 else next;
    local contents = expression[:end];
    self.rawToken(name, contents, expression[realNext:]),

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

  // Tokens that affect parsing state
  stateTokens: [
    self.parseStringToken("'", 'rawString'),
    self.parseStringToken('"', 'idString'),
    self.parseStringToken('`', 'jsonLiteral'),
  ],
  parseComparator(expression): if std.member('=<>!', expression[0:1]) then
    local op =
      if expression[1:2] == '=' then expression[0:2] else expression[0:1];
    local tokens = self.alltokens(expression[std.length(op):], []);
    self.rawToken('comparator', { op: op, tokens: tokens }, null),

  parseFlatten: function(expression)
    if std.startsWith(expression, '[]') then
      self.rawToken('flatten', null, expression[2:]),

  parseFilterProjection(expression):
    local subParser(expression) =
      self.parseSubTokens('filterProjection', expression);
    self.prefix('[?', expression, subParser),

  // The tokens that may be encountered as part of top-level parsing
  topTokens: [
    self.idToken,
    self.parseFilterProjection,
    self.parseSlice,
    self.parseFlatten,
    function(expression) self.prefixParse('[*', 'arrayWildcard', expression),
    function(expression) self.prefixParse('[', 'index', expression),
    function(expression) self.prefix('.', expression, function(expression)
      self.nestingToken('subexpression', expression, null)),
    function(expression) self.prefix('|', expression, function(expression)
      self.nestingToken('pipe', expression, null)),
    self.parseComparator,
    function(expression) if expression[0] == '*' then
      self.rawToken('objectWildcard', '', expression[1:]),
  ] + self.stateTokens,

  // Generic support for parsing strings into tokens.  See stateTokens
  parseStringToken(quote, name, parsers=[]):
    local pu(expression, index) = self.parseUntil(
      expression, quote, index, parsers
    );
    local body(expression) = self.indexRawToken(
      name, expression, pu(expression, 0)
    );
    function(expression) self.prefix(quote, expression, body),

  // Return a token name, text, and remainder
  // Note: the returned text may omit some unneded syntax
  token(expression):
    local result = self.priorityParse(expression, self.topTokens);
    if result != null then result
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

  idToken(expression):
    local condition(expression, offset) =
      offset >= std.length(expression) ||
      !self.idChar(expression[offset], first=offset == 0);
    local end = self.parseUntilCB(
      expression, condition, 0, self.stateTokens
    ).end;
    if end == 0 then null else self.indexRawToken(
      'id', expression, end, next=end
    ),

  stringAdvance(expression, index): { next: index + 1, token: expression[index:self.next] },

  // Returns the index of the next non-string character.
  // This is suitable for searching for terminating characters, such as ']'
  advance(expression, index, parsers=self.stateTokens):
    local next = index + 1;
    local subExpression = expression[index:];
    local result = self.priorityParse(subExpression, parsers);
    local next = if result != null then
      index + std.length(subExpression) - std.length(result.remainder)
    else index + 1;
    {
      next: next,
      token: if result == null then expression[index:next] else result,
    },

  parseUntil(expression, terminal, index, parsers):
    // return the index of the ending character in the expression
    // terminal: The character that ends the token
    // advance: A function to advance the index to the next candidate.
    //  This is designed to support states, such as skipping forward in strings.
    //  See advance and stringAdvance.
    local condition(expression, index) = expression[index] == terminal;
    self.parseUntilCB(
      expression, condition, index, parsers
    ).end,

  parseUntilCB(expression, condition, index, parsers, tokens=[]):
    local advanced = self.advance(expression, index, parsers);
    if condition(expression, index) then { end: index, tokens: tokens }
    else self.parseUntilCB(
      expression, condition, advanced.next, parsers, tokens + [advanced.token]
    ),

  parseTokenTerminator(name, terminator, expression):
    local end = self.parseUntil(expression, terminator, 0, self.stateTokens);
    self.indexRawToken(name, expression, end),

  parseSubTokens(name, expression):
    local result = self.parseUntilCB(
      expression, function(e, i) e[i] == ']', 0, self.stateTokens
    );
    self.nestingToken(
      name, expression[:result.end], expression[result.end + 1:]
    ),

  nestingToken(name, text, remaining):
    self.rawToken(name, self.alltokens(text, []), remaining),

  prefixParse(prefix, name, expression):
    self.prefix(
      prefix, expression, function(expression)
        self.parseTokenTerminator(name, ']', expression)
    ),

  parseSlice(expression):
    local parsed = self.parseTokenTerminator('slice', ']', expression[1:]);
    if expression[0:1] == '[' && std.member(parsed.token.content, ':')
    then parsed,

  // Try a series of parsers in order.
  // Works by constructing a nested if/else expression from the lowest priority
  // upwards, with each expression becoming the "else" in a higher-priority
  // expression.
  priorityParse(expression, parsers):
    std.foldr(
      function(next, prev) local v = next(expression); if v != null then v
      else prev,
      parsers,
      null
    ),

  prefix(prefix, expression, body):
    if std.startsWith(expression, prefix) then
      body(expression[std.length(prefix):]),
}
