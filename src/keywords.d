/// manage keywords used on cli
module keywords;

/// type of action to take
enum OperationType {
  create  , /// record a new transaction
  query   , /// retrieve information on previous transactions
  complete  /// request for bash completion options
}

/// keywords used to identify transaction and query parameters
enum ParameterType {
  source  , /// the source (sender) of a transaction
  dest    , /// the destination (recipient) of a transaction
  date    , /// to date on which a transaction occured
  note    , /// a note about the transaction
  amount  , /// the quantity of money in a transaction
}

private enum operationKeywords = [
  "add"        : OperationType.create,
  "list"       : OperationType.query,
   "_complete" : OperationType.complete,
];

private enum parameterKeywords = [
  "from"   : ParameterType.source,
  "to"     : ParameterType.dest,
  "on"     : ParameterType.date,
  "for"    : ParameterType.note,
  "amount" : ParameterType.amount,
];

/// thrown when a keyword input at the CLI cannot be translated
class KeywordException : Exception {
  /// construct an exception from the invalid keyword `input`
  this(string input) {
    string msg = input ~ " is not a known keyword";
    super(msg);
  }
}

OperationType parseOperationKeyword(string input, string[string] aliases) {
  return parseKeyword!OperationType(input, aliases, operationKeywords);
}

ParameterType parseParameterKeyword(string input, string[string] aliases) {
  return parseKeyword!ParameterType(input, aliases, parameterKeywords);
}

private:
T parseKeyword(T)(string input, string[string] aliases, const T[string] lookup) if (is(T == enum)) {
  input = aliases.get(input, input); // replace input with alias if present
  auto val = input in lookup;        // look up keyword after alias translation
  if (val is null) {
    throw new KeywordException(input);
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
