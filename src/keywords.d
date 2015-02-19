/// manage keywords used on cli
module keywords;

import std.conv : to;

/// type of action to take
enum OperationType {
  invalid , /// indicates failure to identify command type
  create  , /// record a new transaction
  query   , /// retrieve information on previous transactions
  complete  /// request for bash completion options
}

/// keywords used to identify transaction and query parameters
enum ParameterType {
  invalid , /// indicates failure to identify argument type
  source  , /// the source (sender) of a transaction
  dest    , /// the destination (recipient) of a transaction
  date    , /// to date on which a transaction occured
  note    , /// a note about the transaction
  amount  , /// the quantity of money in a transaction
}

T parseKeyword(T)(string keyword, T[string] keywordMap) if (is(T == enum)) {
  return keywordMap.get(keyword, T.init);
}

T parseKeywordType(T)(string key) if (is(T == enum)) {
  try {
    return key.to!T;
  }
  catch {
    return mixin(T.stringof ~ ".invalid");
  }
}

/// `parseKeywordType`
unittest {
  assert("create".parseKeywordType!OperationType    == OperationType.create);
  assert("query".parseKeywordType!OperationType     == OperationType.query);
  assert("nonesense".parseKeywordType!OperationType == OperationType.invalid);
}

/// `parseKeyword`
unittest {
  enum map = [
    "add"       : OperationType.create,
    "list"      : OperationType.query,
    "_complete" : OperationType.complete,
  ];

  assert("add".parseKeyword!OperationType(map)       == OperationType.create);
  assert("list".parseKeyword!OperationType(map)      == OperationType.query);
  assert("_complete".parseKeyword!OperationType(map) == OperationType.complete);
  assert("nope".parseKeyword!OperationType(map)      == OperationType.invalid);
}

