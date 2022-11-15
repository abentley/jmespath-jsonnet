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

  indexRawToken(name, expression, end):
    self.rawToken(name, expression[:end], expression[end:]),

  // Return true if a character is in the supplied range (false otherwise)
  between(char, lowest, highest):
    std.codepoint(char) >= std.codepoint(lowest)
    && std.codepoint(char) <= std.codepoint(highest),

  isDigit(char): self.between(char, '0', '9'),

  // Return true if the character can be part of an unquoted identifier.
  // first: if true, this would be the first character of the identifier
  idChar(char, first): (
    self.between(char, 'a', 'z') ||
    self.between(char, 'A', 'Z') || (
      if first then false else self.isDigit(char)
    )
  ),

  parseComparator(expression): if std.member('=<>!', expression[0:1]) then
    local op =
      if expression[1:2] == '=' then expression[0:2] else expression[0:1];
    local tokens = self.someTokens(expression[std.length(op):]);
    local token = self.rawToken(
      'comparator', { op: op, tokens: tokens.token.content }, tokens.remainder
    );
    token,

  rename(parser, name):
    local wrapper(expression) = (
      local result = parser(expression);
      if result != null then result { token+: { name: name } }
    );
    wrapper,

  parseNaturalNum(expression, found=[]):
    local condition(expression, index) =
      local remainder = expression[index:index + 1];
      remainder == '' || !self.isDigit(remainder);
    self.parseUntilToken(expression, condition, 'naturalNum'),

  parseUntilToken(expression, condition, name):
    local end = self.parseUntil(expression, condition, 0);
    if end != 0 then self.indexRawToken(name, expression, end),

  parseIntToken(expression):
    local parseNegative(expression) = if std.startsWith(expression, '-') then
      local token = self.parseNaturalNum(expression[1:]);
      if token != null then self.rawToken(
        'int', '-' + token.token.content, token.remainder
      );
    local result = self.priorityParse(expression, [
      self.rename(self.parseNaturalNum, 'int'),
      parseNegative,
    ]);
    if result != null then result { token+: {
      content: std.parseInt(super.content),
    } },

  constantParser(constant, name)::
    function(expression)
      if std.startsWith(expression, constant) then
        local end = std.length(constant);
        self.indexRawToken(name, expression, end),

  delimitParser(prefix, suffix, parser):
    self.prefixParser(prefix, self.suffixParser(suffix, parser)),

  // The tokens that may be encountered as part of top-level parsing
  topTokens: [
    self.idToken,
    self.parseComparator,
    self.delimitParser('[?', ']', self.nestingToken('filterProjection')),
    self.rename(self.delimitParser('[', ']', self.parseIntToken), 'index'),
    self.delimitParser('[', ']', self.parseSliceInner),
    self.constantParser('*', 'objectWildcard'),
    self.constantParser('[]', 'flatten'),
    self.constantParser('[*]', 'arrayWildcard'),
    self.prefixParser('.', self.nestingToken('subexpression')),
    self.prefixParser('|', self.nestingToken('pipe')),
    self.stringParser("'", 'rawString'),
    self.stringParser('"', 'idString'),
    self.stringParser('`', 'jsonLiteral'),
  ],

  // Generic support for parsing strings into tokens.
  stringParser(quote, name):
    local condition(expression, index) = expression[index] == quote;
    self.delimitParser(quote, quote, function(expression)
      self.parseUntilToken(expression, condition, name)),

  // Return a token name, text, and remainder
  // Note: the returned text may omit some unneded syntax
  token(expression):
    self.priorityParse(expression, self.topTokens),

  // Return an object containing:
  // - the parsed tokens
  // - the portion of the string that could not be parsed
  someTokens(expression, prevTokens=[], name=null):
    local token = self.priorityParse(expression, self.topTokens);
    local unparsed = if token == null then expression else null;
    local curTokens = prevTokens + if token == null then [] else [token.token];
    if token == null || token.remainder == null then
      self.rawToken(name, curTokens, unparsed)
    else self.someTokens(token.remainder, curTokens, name),

  // Return an array of all tokens
  // Expression must be a string
  alltokens(expression): (
    local result = self.someTokens(expression);
    if result.remainder == null then result.token.content
    else error 'Unhandled expression: %s' % std.manifestJson(result.unparsed)
  ),

  idToken(expression):
    local condition(expression, offset) =
      offset >= std.length(expression) ||
      !self.idChar(expression[offset], first=offset == 0);
    local end = self.parseUntil(
      expression, condition, 0
    );
    if end == 0 then null else self.indexRawToken(
      'id', expression, end
    ),

  // return an object containing the index of the ending character in the
  // expression
  // terminal: The character that ends the token
  parseUntil(expression, condition, index):
    local next = index + 1;
    if condition(expression, index) then index
    else self.parseUntil(expression, condition, next),

  nestingToken(name):
    function(expression) self.someTokens(expression, name=name),

  optionalParser(parser):
    local parseOptional(expression) =
      local tryToken = parser(expression);
      self.rawToken(
        if tryToken != null then tryToken.token.name,
        if tryToken != null then tryToken.token.content,
        if tryToken == null then expression else tryToken.remainder
      );
    parseOptional,

  parseSliceInner(expression):
    local parseOptionalInt = self.optionalParser(self.parseIntToken);
    local start = parseOptionalInt(expression);
    if start.remainder != null then
      local stop = self.prefixParser(':', parseOptionalInt)(start.remainder);
      if stop != null then
        local step = self.optionalParser(
          self.prefixParser(':', parseOptionalInt)
        )(stop.remainder);
        self.rawToken('slice', {
          start: if start != null then start.token.content,
          stop: if stop != null then stop.token.content,
          step: step.token.content,
        }, step.remainder),

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

  prefixParser(prefix, bodyParser):
    function(expression) if std.startsWith(expression, prefix) then
      bodyParser(expression[std.length(prefix):]),

  suffixParser(suffix, bodyParser):
    function(expression)
      local result = bodyParser(expression);
      if result != null && result.remainder != null then
        if std.startsWith(result.remainder, suffix) then
          self.rawToken(
            result.token.name,
            result.token.content,
            result.remainder[std.length(suffix):]
          ),
}
