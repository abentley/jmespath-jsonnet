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

  // Return a token name, text, and remainder
  // Note: the returned text may omit some unneded syntax
  parseToken(expression):
    self.priorityParse(expression, [
      function(expression) if self.idChar(expression[0], first=true) then
        self.idToken(expression),
      function(expression)
        self.prefixParse('[?', 'filterProjection', expression),
      self.parseSlice,
      function(expression) self.prefixParse('[]', 'flatten', expression),
      function(expression) self.prefixParse('[*', 'arrayWildcard', expression),
      function(expression) self.prefixParse('[', 'index', expression),
      function(expression) if expression[0] == '.' then
        self.rawToken('subexpression', expression[1:], null),
      function(expression) if expression[0] == '|' then
        self.rawToken('pipe', expression[1:], null),
      function(expression) if std.member('=<>!', expression[0:1]) then
        self.rawToken('comparator', expression, null),
      function(expression) if expression[0] == "'" then
        self.rawEndToken('rawString', expression, self.parseRawString),
      function(expression) if expression[0] == '"' then
        self.rawEndToken('idString', expression, self.parseIdentifierString),
      function(expression) if expression[0] == '`' then
        self.rawEndToken('jsonLiteral', expression, self.parseJsonString),
      function(expression) if expression[0] == '*' then
        self.indexRawToken('objectWildcard', expression, 0),
    ]),

  // Return a token name, text, and remainder
  // Note: the returned text may omit some unneded syntax
  token(expression):
    local result = self.parseToken(expression);
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
      expression, condition, 0, self.advance
    );
    self.indexRawToken('id', expression, end, next=end),

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
    local condition(expression, index) = expression[index] == terminal;
    self.parseUntilCB(
      expression, condition, index, advance
    ),

  parseUntilCB(expression, condition, index, advance):
    local next = advance(expression, index);
    if condition(expression, index) then index
    else self.parseUntilCB(expression, condition, next, advance),

  parseTokenTerminator(name, terminator, expression):
    local subExpression = expression[1:];
    local end = self.parseUntil(subExpression, terminator, 0, self.advance);
    self.indexRawToken(name, subExpression, end),

  prefixParse(prefix, name, expression):
    if std.startsWith(expression, prefix) then
      self.parseTokenTerminator(name, ']', expression),

  parseSlice(expression):
    local parsed = self.parseTokenTerminator('slice', ']', expression);
    if expression[0:1] == '[' && std.member(parsed.token.content, ':')
    then parsed,

  parseIndexToken(expression):
    self.prefixParse('[', 'index', expression),

  priorityParse(expression, parsers):
    std.foldr(
      function(next, prev) local v = next(expression); if v != null then v
      else prev,
      parsers,
      null
    ),

  bracketToken(expression):
    self.priorityParse(expression, [
      function(expression)
        self.prefixParse('[?', 'filterProjection', expression),
      self.parseSlice,
      function(expression) self.prefixParse('[]', 'flatten', expression),
      function(expression) self.prefixParse('[*', 'arrayWildcard', expression),
      function(expression) self.prefixParse('[', 'index', expression),
    ]),

  rawEndToken(name, expression, parseUntil):
    local subExpression = expression[1:];
    self.indexRawToken(name, subExpression, parseUntil(subExpression, 0)),
}
