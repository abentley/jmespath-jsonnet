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
local alltokens = (import 'tokens.libsonnet').alltokens;
local countUp(items) = std.range(0, std.length(items) - 1);


local mapContents(data, func, next) =
  if next == null then func(data)
  else next.map(data, func, null, allow_projection=true);

{
  maybeJoin(prev, value):
    if prev != null then self.joiner(prev, value) else value,

  local maybeJoin = self.maybeJoin,

  ImplCurrent: {
    search(data, next)::
      if next != null then next.search(data, null)
      else data,
    map(data, func, next, allow_projection)::
      if next != null then next.map(data, func, null, allow_projection)
      else func(data),
  },

  current(value, prev=null): self.ImplCurrent {
  },

  ImplMember: {
    searchNext(result, next)::
      if next == null || result == null then result
      else next.search(result, null),
    search(data, next)::
      self.searchNext(self.searchResult(data), next),
  },
  ImplIdSegment: self.ImplMember {
    searchResult(data)::
      if std.type(data) != 'object' || !std.objectHasAll(data, self.id)
      then null
      else data[self.id],

    map(data, func, next, allow_projection)::
      local result = self.searchResult(data);
      if std.type(data) != 'object' || !std.objectHasAll(data, self.id)
      then data
      else data { [self.id]: mapContents(result, func, next) },
    repr():: self.id,
  },

  // A segment of an identifier.
  id(id, prev=null):
    assert prev == null : std.toString(prev);
    self.ImplIdSegment { type: 'id', id: id },

  // A segment of an identifier.
  idString(id, prev=null):
    self.id(id, prev),

  ImplIndex: self.ImplMember {
    dataIndex(data)::
      if self.index < 0
      then std.length(data) + self.index
      else self.index,

    searchResult(data)::
      local index = self.dataIndex(data);
      if std.type(data) == 'array'
         && index < std.length(data)
         && index >= 0 then
        data[index],

    map(data, func, next, allow_projection)::
      local index = self.dataIndex(data);
      if std.type(data) != 'array' then data else std.mapWithIndex(
        function(i, e)
          if i == index then mapContents(e, func, next) else e,
        data,
      ),
    repr():: '[%d]' % self.index,
  },

  // An expression object for looking up by index
  index(index, prev=null):
    self.maybeJoin(prev, self.ImplIndex {
      type: 'index',
      index: index,
    }),

  ImplProjection: {

    searchResult(data)::
      local matching = self.getMatching(data);
      [data[i] for i in countUp(data) if bool(matching[i])],

    searchNext(result, next)::
      if result == null || next == null then result else [
        r
        for r in [next.search(v, null) for v in result]
        if r != null
      ],

    search(data, next)::
      self.searchNext(self.searchResult(data), next),

    map(data, func, next, allow_projection)::
      local matching = self.getMatching(data);
      if allow_projection then std.mapWithIndex(
        function(i, e)
          if bool(matching[i]) then mapContents(e, func, next) else e,
        data,
      ) else mapContents(data, func, next),
  },

  ImplSlice: self.ImplProjection {
    searchResult(data)::
      local length = std.length(data);
      local integerStep = if self.step == null then 1 else self.step;
      local stepStart = if integerStep < 0 then self.stop else self.start;
      local stepStop = if integerStep < 0 then self.start else self.stop;
      local positiveStart = std.max(0, if stepStart == null then 0
      else (if stepStart < 0 then length + stepStart else stepStart) + (
        if integerStep < 0 then 1 else 0
      ));
      local positiveStop = std.max(
        0,
        if stepStop == null then length
        else (if stepStop < 0 then length + stepStop
              else stepStop) + (if integerStep < 0 then 1 else 0)
      );
      local limited = data[positiveStart:positiveStop];
      local ordered = if integerStep < 0 then std.reverse(limited) else limited;
      if std.type(data) == 'array' then
        ordered[::std.abs(integerStep)],

    getMatching(data)::
      local dataIndices = countUp(data);
      local included = std.set(self.searchResult(dataIndices));
      [std.setMember(di, included) for di in dataIndices],

    repr():: '[%s:%s%s]' % [
      if self.start == null then '' else self.start,
      if self.stop == null then '' else self.stop,
      if self.step == null then '' else ':%d' % self.step,
    ],
  },

  flatten(flattenExpr, prev):: self.maybeJoin(prev, self.ImplProjection {

    searchResult(data):: std.foldl(
      function(l, r) l + if std.type(r) == 'array' then r else [r], data, []
    ),

    map(data, func, next, allow_projection)::
      if allow_projection then [
        if std.type(e) == 'array' then [mapContents(f, func, next) for f in e]
        else mapContents(e, func, next)
        for e in data
      ]
      else self.unflatten(data, mapContents(
        self.searchResult(data), func, next
      )),
    unflatten(original, flattened)::
      local current = original[0];
      if std.length(original) == 0 then []
      else if std.type(current) == 'array' then
        local end = std.length(current);
        [flattened[0:end]] + self.unflatten(original[1:], flattened[:end])
      else [flattened[0]] + self.unflatten(original[1:], flattened[1:]),
    repr():: '[]',
  }),

  arrayWildcard(expr, prev):: self.maybeJoin(prev, self.ImplProjection {
    searchResult(data):: data,
    getMatching(data):: std.repeat([true], std.length(data)),
    repr():: '[*]',
  }),

  objectWildcard(expr, prev):: self.maybeJoin(prev, self.ImplProjection {
    searchResult(data)::
      if std.type(data) == 'object' then std.objectValues(data),
    map(data, func, next, allow_projection)::
      local fieldsOrder = std.objectFields(data);
      if allow_projection then {
        [f]: mapContents(data[f], func, next)
        for f in fieldsOrder
      }
      else
        local values = mapContents([data[f] for f in fieldsOrder], func, next);
        { [fieldsOrder[i]]: values[i] for i in countUp(fieldsOrder) },
    repr():: '*',
  }),

  slice(sliceExpr, prev=null):
    local splitExpr = std.splitLimit(sliceExpr, ':', 3);
    local intOrNull(expr) = if expr == '' then null else std.parseInt(expr);
    local start = intOrNull(splitExpr[0]);
    local stop =
      if std.length(splitExpr) < 2 then null else intOrNull(splitExpr[1]);
    local step =
      if std.length(splitExpr) < 3 then null else intOrNull(splitExpr[2]);
    self.maybeJoin(prev, self.ImplSlice {
      start: sliceExpr.start,
      stop: sliceExpr.stop,
      step: sliceExpr.step,
    }),

  ImplFilterProjection:: self.ImplProjection {
    getMatching(data)::
      [self.comparator.evaluate(d) for d in data],
    repr():: '[?%s]' % self.comparator.repr(),
  },

  filterProjection(sliceExpr, prev=null)::
    local comparator = self.compileTokens(sliceExpr);
    self.ImplFilterProjection {
      comparator: comparator,
    },

  ImplJoiner: {
    search(data, next)::
      local next2 = maybeJoin(self.right, next);
      self.left.search(data, next2),
    map(data, func, next, allow_projection)::
      self.left.map(
        data, func, maybeJoin(self.right, next), allow_projection=true,
      ),
    repr():: std.join('', [self.left.repr(), self.right.repr()]),
  },

  // A mostly-invisible connector used for joining array accesses into one big
  // connector
  joiner(left, right): self.ImplJoiner {
    type: 'joiner',
    right: right,
    left: left,
  },

  implSubExpression: {
    repr():: std.join('.', [self.left.repr(), self.right.repr()]),
  },

  // Represent both sides of a dot.
  subexpression(content, prev):
    self.joiner(prev, self.compileTokens(content, null)) + (
      self.implSubExpression {
        type: 'subexpression',
      }
    ),

  implPipe: {
    search(data, next):
      local rdata =
        if self.left == null then data else self.left.search(data, null);
      self.right.search(rdata, next),
    map(data, func, next, allow_projection)::
      if self.left == null then self.right.map(data,
                                               func,
                                               null,
                                               allow_projection=false)
      else self.left.map(data, func, self.right, allow_projection=false),
    repr():: std.join('|', [self.left.repr(), self.right.repr()]),
  },

  // Represent both sides of a pipe.
  pipe(content, prev):
    self.joiner(prev, self.compileTokens(content, null)) + self.implPipe {
      type: 'pipe',
    },

  local bool(value) =
    !std.member([null, [], {}, '', false], value),

  ImplBoolean: {
    search(data, next)::
      self.pickSide(data, next).search(data, next),
    map(data, func, next, allow_projection)::
      self.pickSide(data, next).map(data, func, next, allow_projection),
  },
  boolean(content, prev)::
    local right = self.compileTokens(content); self.ImplBoolean {
      left: prev,
      right: right,
    },
  ImplOr: {
    pickSide(data, next)::
      if bool(self.left.search(data, next)) then self.left
      else self.right,
  },
  or(content, prev)::
    self.boolean(content, prev) + self.ImplOr,

  ImplAnd: {
    pickSide(data, next)::
      if !bool(self.left.search(data, next)) then self.left
      else self.right,
  },
  and(content, prev)::
    self.boolean(content, prev) + self.ImplAnd,

  ImplNot: {
    search(data, next):: !bool(self.expression.search(data, next)),
  },

  not(content, prev)::
    local expression = self.compileTokens(content);
    self.ImplNot {
      expression: expression,
    },

  ImplJsonLiteral: {
    search(data, next):: self.literal,
    repr()::
      local contents =
        if std.type(self.literal) == 'string' then std.escapeStringJson(
          self.literal
        )
        else std.toString(self.literal);
      '`%s`' % contents,
  },

  jsonLiteral(content, prev): self.ImplJsonLiteral {
    literal: std.parseJson(content),
  },

  ImplRawString: self.ImplJsonLiteral {
    repr()::
      local escaped = std.escapeStringJson(self.literal);
      "'%s'" % escaped[1:std.length(escaped) - 1],
  },

  rawString(string, prev): self.ImplRawString {
    literal: string,
  },

  whitespace(string, prev): prev,

  ImplComparator:: {
    evaluate(data):: self.opFunc[self.op](
      self.left.search(data, null), self.right.search(data, null)
    ),
    search(data, next):: self.evaluate(data),
    map(data, next, value, allow_projection):: data,
    local makeCompareFunc(basefunc) =
      function(l, r)
        if std.type(l) != 'number' || std.type(r) != 'number' then null
        else basefunc(l, r),

    opFunc:: {
      '==': function(l, r) l == r,
      '!=': function(l, r) l != r,
      '<': makeCompareFunc(function(l, r) l < r),
      '<=': makeCompareFunc(function(l, r) l <= r),
      '>': makeCompareFunc(function(l, r) l > r),
      '>=': makeCompareFunc(function(l, r) l >= r),
    },
    repr(): '%s%s%s' % [self.left.repr(), self.op, self.right.repr()],
  },
  comparator(expr, prev)::
    local compile = self.compile;
    local right = self.compileTokens(expr.tokens);
    self.ImplComparator {
      left: prev,
      right: right,
      op: expr.op,
    },
  ok(value): {
    ok: value,
  },
  local ok = self.ok,
  err(kind, value): {
    err: { kind: kind, value: value },
  },
  local err = self.err,
  unwrap(result):
    if std.objectHas(result, 'ok') then result.ok
    else error '%s %s' % [result.err.kind, result.err.value],
  local unwrap = self.unwrap,
  ImplFunction: {
    local typeCheck(sType) =
      function(i, v)
        local vType = std.type(v);
        if vType != sType then err(
          'invalid-type',
          'Argument %d had type "%s" instead of "%s"' % [
            i,
            vType,
            sType,
          ]
        ),
    local typesCheck(types) =
      function(i, v)
        if !std.member(types, std.type(v))
        then err(
          'invalid-type', 'Invalid type: %s' % std.type(v)
        ),
    local arrayCheck(sType) =
      function(i, v)
        if std.type(v) != 'array' then err(
          'invalid-type', 'Invalid type: %s' % std.type(v)
        ) else if v == [] then null else
          local aTypes = std.set([std.type(a) for a in v]);
          if aTypes != [sType] then err(
            'invalid-type',
            'Argument %d had types "%s" instead of "%s"' % [
              i,
              std.join(', ', aTypes),
              sType,
            ]
          ),
    local arrayCheckNumString() =
      function(i, v)
        local result = arrayCheck('number')(i, v);
        if result == null then result
        else arrayCheck('string')(i, v),
    local anyCheck(i, v) = null,
    local apply(callable, args) = [
      function() callable(),
      function() callable(args[0]),
      function() callable(args[0], args[1]),
    ][std.length(args)](),
    functions:: {
      abs: {
        callable: std.abs,
        argChecks: [typeCheck('number')],
      },
      avg: {
        callable(elements):
          if elements != [] then
            sum(elements) / std.length(elements),
        argChecks: [arrayCheck('number')],
      },
      contains: {
        callable(subject, search):
          if std.type(subject) == 'string' && std.type(search) != 'string'
          then false
          else std.member(subject, search),
        argChecks: [
          typesCheck(['string', 'array']),
          anyCheck,
        ],
      },
      ceil: {
        callable: std.ceil,
        argChecks: [typeCheck('number')],
      },
      ends_with: {
        argChecks: [typeCheck('string'), typeCheck('string')],
        callable: std.endsWith,
      },
      floor: {
        callable: std.floor,
        argChecks: [typeCheck('number')],
      },
      join: {
        argChecks: [typeCheck('string'), arrayCheck('string')],
        callable: std.join,
      },
      keys: {
        argChecks: [typeCheck('object')],
        callable: std.objectFields,
      },
      length: {
        argChecks: [typesCheck(['string', 'array', 'object'])],
        callable: std.length,
      },
      max: {
        argChecks: [arrayCheckNumString()],
        callable(collection):
          if std.length(collection) == 0 then null
          else if std.type(collection[0]) == 'number' then
            std.foldl(std.max, collection[1:], collection[0])
          else
            std.sort(collection)[std.length(collection) - 1],
      },
      merge: {
        argChecks: null,
        callable(collection): std.foldl(
          function(l, r) l + r, collection[1:], collection[0]
        ),
      },
      min: {
        argChecks: [arrayCheckNumString()],
        callable(collection):
          if std.length(collection) == 0 then null
          else if std.type(collection[0]) == 'number' then
            std.foldl(std.min, collection[1:], collection[0])
          else
            std.sort(collection)[0],
      },
      not_null: {
        argChecks: null,
        callable(args):
          local comp = [x for x in args if x != null];
          if comp != [] then comp[0],
      },
      reverse: {
        argChecks: [typesCheck(['array', 'string'])],
        callable(argument):
          local result = std.reverse(argument);
          if std.type(argument) == 'string' then std.join('', result)
          else result,
      },
      starts_with: {
        argChecks: [typeCheck('string'), typeCheck('string')],
        callable: std.startsWith,
      },
      to_array: {
        argChecks: [anyCheck],
        callable(arg): if std.type(arg) == 'array' then arg else [arg],
      },
      to_number: {
        argChecks: [anyCheck],
        callable(arg):
          local type = std.type(arg);
          if type == 'string' then
            local json = std.parseJson(arg);
            if std.type(json) == 'number' then json else null
          else if type == 'number' then arg,
      },
      type: {
        argChecks: [anyCheck],
        callable: std.type,
      },
      values: {
        argChecks: [typeCheck('object')],
        callable: std.objectValues,
      },
      local sum(collection) = std.foldl(function(l, r) l + r, collection, 0),
      sum: {
        callable(elements):
          sum(elements),
        argChecks: [arrayCheck('number')],
      },
    },
    call(name, args)::
      if !std.objectHas(self.functions, name)
      then err('Unknown function', name)
      else
        local info = self.functions[name];
        if info.argChecks == null then ok(info.callable(args))
        else if std.length(args) != std.length(info.argChecks) then err(
          'invalid-arity',
          'Expected %d arguments, got %d' % [
            std.length(info.argChecks),
            std.length(args),
          ]
        )
        else
          local argErrors = [e for e in std.mapWithIndex(
            function(i, v) info.argChecks[i](i, v), args
          ) if e != null];
          if std.length(argErrors) > 0 then argErrors[0]
          else ok(apply(info.callable, args)),
    search(data, next)::
      unwrap(self.call(self.name, [a.search(data, null) for a in self.args])),
    map(data, func, next, allow_projection):: data,
    repr():: '%s(%s)' % [
      self.name,
      std.join(', ', [a.repr() for a in self.args]),
    ],
  },
  'function'(content, prev):
    local args = [self.compileTokens(a) for a in content.args];
    self.ImplFunction {
      type: 'function',
      name: content.name,
      args: args,
    },
  // Return an object representing the expression
  // Expression must be a string
  compile(expression, prev=null): (
    self.compileTokens(alltokens(expression), prev)
  ),
  // Return an object representing the expression
  // Expression must be a string
  compileTokens(tokens, prev=null): (
    std.foldl(
      function(prev, token) self[token.name](token.content, prev=prev),
      tokens,
      null
    )
  ),
}
