/// manage keywords used on cli
module keywords;

import std.conv : to;

/// type of action to take
enum CommandType {
  invalid, /// indicates failure to identify command type
  create,  /// record a new transaction
  query,   /// retrieve information on previous transactions
  complete /// request for bash completion options
}

/// keywords used to identify transaction and query parameters
enum ArgKeyword {
  invalid, /// indicates failure to identify argument type
  source,  /// the source (sender) of a transaction
  dest  ,  /// the destination (recipient) of a transaction
  date  ,  /// to date on which a transaction occured
  note  ,  /// a note about the transaction
  amount,  /// the quantity of money in a transaction
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
  assert("create".parseKeywordType!CommandType == CommandType.create);
  assert("query".parseKeywordType!CommandType == CommandType.query);
  assert("nonesense".parseKeywordType!CommandType == CommandType.invalid);
}

/// `parseKeyword`
unittest {
  enum map = [
    "add"       : CommandType.create,
    "list"      : CommandType.query,
    "_complete" : CommandType.complete,
  ];

  assert("add".parseKeyword!CommandType(map)       == CommandType.create);
  assert("list".parseKeyword!CommandType(map)      == CommandType.query);
  assert("_complete".parseKeyword!CommandType(map) == CommandType.complete);
  assert("nope".parseKeyword!CommandType(map)      == CommandType.invalid);
}

