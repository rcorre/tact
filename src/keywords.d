/// manage keywords used on cli
module keywords;

import std.conv : to;
import std.typecons : Flag, Yes, No;

/// type of action to take
enum OperationType {
  create  , /// record a new transaction
  query   , /// retrieve information on previous transactions
  remove  , /// remove transactions matching from storage
  edit    , /// edit transactions matching query
  balance , /// sum all transactions for an account
  help    , /// requres usage information, either in general or for a command
  complete  /// request for bash completion options
}

/// keywords used to identify transaction and query parameters
enum ParameterType {
  source  , /// the source (sender) of a transaction
  dest    , /// the destination (recipient) of a transaction
  date    , /// to date on which a transaction occured
  note    , /// a note about the transaction
  amount  , /// the quantity of money in a transaction
  sort    , /// ascending sort parameter
  revsort , /// descending sort parameter
}

private enum operationKeywords = [
  "add"        : OperationType.create,
  "list"       : OperationType.query,
  "remove"     : OperationType.remove,
  "edit"       : OperationType.edit,
  "balance"    : OperationType.balance,
  "help"       : OperationType.help,
   "_complete" : OperationType.complete,
];

private enum parameterKeywords = [
  "from"   : ParameterType.source,
  "to"     : ParameterType.dest,
  "on"     : ParameterType.date,
  "for"    : ParameterType.note,
  "amount" : ParameterType.amount,
  "sort"   : ParameterType.sort,
  "revsort": ParameterType.revsort,
];

/// defines the criteria for a sort argument
struct SortParameter {
  ParameterType field;        /// field to sort by
  Flag!"ascending" ascending; /// if Ascending.yes, low values first; otherwise high values first
}

/// thrown when a keyword input at the CLI cannot be translated
class KeywordException : Exception {
  /// construct an exception from the invalid keyword `input`
  this(string msg) {
    super(msg);
  }
}

OperationType parseOperationKeyword(string input, string[string] aliases) {
  return parseKeyword!OperationType(input, aliases, operationKeywords);
}

ParameterType parseParameterKeyword(string input, string[string] aliases) {
  return parseKeyword!ParameterType(input, aliases, parameterKeywords);
}

/// extract a sort argument
/// Params:
///   sortType: `sort` or `revsort`
///   sortParam: string representing a `ParameterType` to order by
///   aliases: maps custom keywords to default keywords
/// Returns: `SortParameter` which specifies field to sort on and ascending/descending sort
SortParameter parseSortParameter(ParameterType sortType, string sortParam, string[string] aliases) {
  assert(sortType == ParameterType.sort || sortType == ParameterType.revsort,
      "parseSortParameter expected sortType or sort or revsort, not " ~ sortType.to!string);

  auto param = parseKeyword!ParameterType(sortParam, aliases, parameterKeywords);
  if (param == ParameterType.sort || param == ParameterType.revsort) {
    throw new KeywordException("Cannot sort by " ~ sortParam);
  }

  SortParameter s;
  // field to sort by
  s.field = param;
  // if sort, ascending. if revsort, descending
  s.ascending = (sortType == ParameterType.sort) ? Yes.ascending : No.ascending;
  return s;
}

private:
T parseKeyword(T)(string input, string[string] aliases, const T[string] lookup) if (is(T == enum)) {
  input = aliases.get(input, input); // replace input with alias if present
  auto val = input in lookup;        // look up keyword after alias translation
  if (val is null) {
    throw new KeywordException(input ~ " is not a known keyword");
  }
  return *val;
}

/// `parseOperationKeyword` and `parseParameterKeyword`
unittest {
  import std.exception : assertThrown;

  enum opAlias = [
    "new"   : "add",
    "query" : "list",
  ];

  enum cmdAlias = [
    "amt"   : "amount"
  ];

  assert("add".parseOperationKeyword(opAlias)       == OperationType.create);
  assert("new".parseOperationKeyword(opAlias)       == OperationType.create);
  assert("list".parseOperationKeyword(opAlias)      == OperationType.query);
  assert("query".parseOperationKeyword(opAlias)     == OperationType.query);
  assert("_complete".parseOperationKeyword(opAlias) == OperationType.complete);

  assert("amt".parseParameterKeyword(cmdAlias)    == ParameterType.amount);
  assert("amount".parseParameterKeyword(cmdAlias) == ParameterType.amount);
  assert("from".parseParameterKeyword(cmdAlias)   == ParameterType.source);

  assertThrown!KeywordException("nope".parseOperationKeyword(opAlias));
  assertThrown!KeywordException("nope".parseParameterKeyword(opAlias));
}

/// `parseSortParameter`
unittest {
  import std.exception : assertThrown;
  assert(parseSortParameter(ParameterType.sort, "amount", null) ==
      SortParameter(ParameterType.amount, Yes.ascending));

  assert(parseSortParameter(ParameterType.revsort, "on", null) ==
      SortParameter(ParameterType.date, No.ascending));

  auto aliases = [ "orderby" : "sort", "src" : "from" ];
  assert(parseSortParameter(ParameterType.revsort, "src", aliases) ==
      SortParameter(ParameterType.source, No.ascending));
}
