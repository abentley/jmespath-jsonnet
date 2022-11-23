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
local exprFactory = (import 'expr_factory.libsonnet');
local jmespath = {
  // Return matching items
  search(expression, data):
    local compiled = self.compile(expression);
    compiled.search(data, null),

  set(expression, data, value): self.map(expression, data, function(x) value),

  map(expression, data, func):
    local compiled = self.compile(expression);
    compiled.map(data, func, null, allow_projection=true),

  patch(expression, data, patch):
    self.map(expression, data, function(x) x + patch),

  compile(expression): if std.type(expression) != 'string' then expression else
    local x = exprFactory.compile(expression); x,
};

jmespath
