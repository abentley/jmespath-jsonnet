local ok(value) = {
  ok: value,
};
local err(kind, value) = {
  err: { kind: kind, value: value },
};
local anyCheck(i, v) = null;

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
    );

local typesCheck(types) =
  function(i, v)
    if !std.member(types, std.type(v))
    then err(
      'invalid-type', 'Invalid type: %s' % std.type(v)
    );

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
      );

local arrayCheckNumString() =
  function(i, v)
    local result = arrayCheck('number')(i, v);
    if result == null then result
    else arrayCheck('string')(i, v);

local functionMap = {
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
  sort: {
    argChecks: [arrayCheckNumString()],
    callable(list):
      std.sort(list),
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
  to_string: {
    argChecks: [anyCheck],
    callable: std.toString,
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
};

{
  local apply(callable, args) = [
    function() callable(),
    function() callable(args[0]),
    function() callable(args[0], args[1]),
  ][std.length(args)](),
  err:: err,
  ok:: ok,
  functionMap: functionMap,
  call(name, args)::
    if !std.objectHas(self.functionMap, name)
    then err('Unknown function', name)
    else
      local info = self.functionMap[name];
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
}
