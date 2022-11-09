# JMESPath-Jsonnet: it's JMESPath in Jsonnet

JMESPath is a way of getting specific values out of JSON documents.  It has
some support for generating JSON as the result.  See http://jmespath.org

Jsonnet is a powerful, functional programming language whose output is JSON
that is typically used to generate configuration.  See http://jsonnet.org

JMESPath-Jsonnet is the Reese's Peanut Butter Cups of these.  It provides a
concice way to query values within a Jsonnet structure, but that's not all.  It
also generating *modified* documents, with JMESPath queries selecting elements
for modification.

JMESPath-Jsonnet currently supports a subset of JMESPath funtionality,
including:

 * identifiers
 * double-quoted identifiers
 * indexing
 * Slices
 * flatten projections
 * object and array wildcard projections
 * filter projections
 * subexpressions
 * pipes
 * json literals
 * single-quoted strings