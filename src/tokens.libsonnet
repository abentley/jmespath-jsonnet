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

  isHexDigit(char): self.isDigit(char) ||
                    self.between(char, 'a', 'f') ||
                    self.between(char, 'A', 'F'),

  // Return true if the character can be part of an unquoted identifier.
  // first: if true, this would be the first character of the identifier
  idChar(char, first): (
    char == '_' ||
    self.between(char, 'a', 'z') ||
    self.between(char, 'A', 'Z') || (
      if first then false else self.isDigit(char)
    )
  ),

  parseComparator(expression):
    local op =
      if std.member(['!=', '=='], expression[0:2]) then expression[0:2] else
        if std.member('<>', expression[0:1]) then
          if expression[1:2] == '=' then expression[0:2] else expression[0:1];
    local tokens = self.someTokens(expression[std.length(op):]);
    local token = self.rawToken(
      'comparator', { op: op, tokens: tokens.token.content }, tokens.remainder
    );
    if op != null then token,

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

  skipWhitespace(expression):
    self.optionalParser(self.parseWhitespace)(expression).remainder,

  parseEscapedString(escaped, result=''):
    local nextChar = escaped[0:1];
    local unescaped = self.parseEscapedChar(escaped, result);
    if unescaped != null then unescaped
    else if nextChar == '"' then { remainder: escaped, result: result }
    else if nextChar == '' then null
    else if self.between(nextChar, ' ', '!') ||
            self.between(nextChar, '#', '[') ||
            self.between(nextChar, ']', '￿') then
      self.parseEscapedString(escaped[1:], result + nextChar),

  escapes: {
    @'\': @'\',
    '/': '/',
    '"': '"',
    b: '\b',
    f: '\f',
    n: '\n',
    r: '\r',
    t: '\t',
  },

  parseHex(str):
    if std.foldl(function(x, y) x && self.isHexDigit(y), str, true) then
      std.parseHex(str),

  parseEscapedChar(escaped, result):
    local nextChar = escaped[1:2];
    local output =
      if std.objectHas(self.escapes, nextChar) then
        self.parseEscapedString(escaped[2:], result + self.escapes[nextChar])
      else if nextChar == 'u' && std.length(escaped[2:]) >= 4 then
        local codepoint = self.parseHex(escaped[2:6]);
        if codepoint != null then
          local newResult = result + std.char(codepoint);
          self.parseEscapedString(escaped[6:], newResult);
    if escaped[0:1] == @'\' then output,


  parseIntToken: self.whitespaceParser(self.parseIntTokenInner),

  parseIntTokenInner(expression):
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

  // Return a parser that skips whitespace on either side
  whitespaceParser(parser)::
    function(expr)
      local expression = self.skipWhitespace(expr);
      local result = parser(expression);
      if result != null then
        self.rawToken(
          result.token.name,
          result.token.content,
          self.skipWhitespace(result.remainder)
        ),

  constantParser(constant, name)::
    function(expression)
      if expression != null && std.startsWith(expression, constant) then
        local end = std.length(constant);
        self.indexRawToken(name, expression, end),

  delimitParser(prefix, suffix, parser):
    self.prefixParser(prefix, self.suffixParser(suffix, parser)),

  // The tokens that may be encountered as part of top-level parsing
  subTokens: [
    self.functionParser,
    self.idToken,
    self.parseComparator,
    self.delimitParser('[?', ']', self.nestingToken('filterProjection')),
    self.rename(self.delimitParser('[', ']', self.parseIntToken), 'index'),
    self.delimitParser('[', ']', self.parseSliceInner),
    self.constantParser('@', 'current'),
    self.constantParser('*', 'objectWildcard'),
    self.delimitParser('[', ']', self.whitespaceParser(
      self.constantParser('', 'flatten')
    )),
    self.delimitParser('[', ']', self.whitespaceParser(
      self.constantParser('*', 'arrayWildcard')
    )),
    self.prefixParser('.', self.nestingToken('subexpression')),
    self.prefixParser('||', self.nestingToken('or')),
    self.prefixParser('&&', self.nestingToken('and')),
    self.prefixParser('!', self.nestingToken('not')),
    self.stringParser("'", 'rawString'),
    self.delimitParser('"', '"', self.parseIdString),
    self.stringParser('`', 'jsonLiteral'),
    self.parseWhitespace,
  ],

  ultraTokens: self.subTokens + [
    self.prefixParser('|', self.nestingToken('pipe')),
  ],

  // Generic support for parsing strings into tokens.
  stringParser(quote, name):
    local condition(expression, index) = expression[index:index + 1] == quote;
    self.delimitParser(quote, quote, function(expression)
      self.parseUntilToken(expression, condition, name)),

  parseIdString(str):
    local content = self.parseEscapedString(str);
    if content != null then
      self.rawToken('idString', content.result, content.remainder),

  parseWhitespace(expression):
    local condition(expression, index) = !std.member(
      ' \n', expression[index:index + 1]
    );
    self.parseUntilToken(expression, condition, 'whitespace'),

  // Return a token name, text, and remainder
  // Note: the returned text may omit some unneded syntax
  token(expression):
    self.priorityParse(expression, self.subTokens),

  // Return an object containing:
  // - the parsed tokens
  // - the portion of the string that could not be parsed
  someTokens(expression, prevTokens=[], name=null, parsers=self.subTokens):
    local token = self.priorityParse(expression, parsers);
    local unparsed = if token == null then expression else null;
    local curTokens = prevTokens + if token == null then [] else [token.token];
    if token == null || token.remainder == null then
      self.rawToken(name, curTokens, unparsed)
    else self.someTokens(token.remainder, curTokens, name, parsers),

  // Return an array of all tokens
  // Expression must be a string
  alltokens(expression): (
    local result = self.someTokens(expression, parsers=self.ultraTokens);
    if result.remainder == null then result.token.content
    else error 'Unhandled expression: %s' % std.manifestJson(result.remainder)
  ),

  idToken(expression):
    local condition(expression, offset) =
      offset >= std.length(expression) ||
      !self.idChar(expression[offset], first=offset == 0);
    local end = self.parseUntil(expression, condition, 0);
    if end == 0 then null else self.indexRawToken(
      'id', expression, end
    ),

  // return an object containing the index of the ending character in the
  // expression
  // terminal: The character that ends the token
  parseUntil(expression, condition, index):
    if condition(expression, index) then index
    else self.parseUntil(expression, condition, index + 1),

  nestingToken(name):
    function(expression)
      local result = self.someTokens(expression, name=name);
      result,

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

  pairParser(firstParser, secondParser):
    function(expression)
      local first = firstParser(expression);
      local second = if first != null then secondParser(first.remainder);
      if second != null then
        self.rawToken('pair', {
          first: first.token,
          second: second.token,
        }, second.remainder),

  prefixParser(prefix, bodyParser):
    local subparser = self.pairParser(
      self.constantParser(prefix, null), bodyParser
    );
    function(expression)
      local pair = subparser(expression);
      local second = if pair != null then pair.token.content.second;
      if second != null then
        self.rawToken(second.name, second.content, pair.remainder),

  suffixParser(suffix, bodyParser):
    local subparser = self.pairParser(
      bodyParser, self.constantParser(suffix, null)
    );
    function(expression)
      local pair = subparser(expression);
      local first = if pair != null then pair.token.content.first;
      if first != null then
        self.rawToken(first.name, first.content, pair.remainder),

  functionParser(expression):
    local result = self.pairParser(
      self.idToken, self.delimitParser('(', ')', self.argsParser),
    )(expression);
    if result != null then
      local content = result.token.content;
      self.rawToken('function', {
        name: content.first.content,
        args: content.second.content,
      }, result.remainder),

  argsParser(expression, pastArgs=[]):
    if expression != null && expression[:1] == ')' then
      self.rawToken('args', pastArgs, expression)
    else
      local arg = self.someTokens(expression, parsers=self.subTokens);
      if arg != null
      then local subExpr =
        if arg.remainder[:1] == ','
        then arg.remainder[1:] else arg.remainder;
           local content = arg.token.content;
           self.argsParser(subExpr, pastArgs + [content]),
}
