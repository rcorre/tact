/// filter a list of transactions by certain criteria 
module query;

import std.path      : globMatch;
import std.datetime  : Date;
import std.algorithm : filter;
import transaction;

/// encapsulates query parameters provided by user to a query command
struct Query {
  /// include transaction in query if `transaction.amount >= minAmount`
  float minAmount = -float.max;
  /// include transaction in query if `transaction.amount <= maxAmount`
  float maxAmount = float.max;
  /// include transaction in query if `transaction.date >= minDate`
  Date minDate = Date.min;
  /// include transaction in query if `transaction.date <= maxDate`
  Date maxDate = Date.max;
  /// include transaction in query if source matches glob
  string sourceGlob = "*";
  /// include transaction in query if destination matches glob
  string destGlob = "*";
  /// include transaction in query if note matches glob
  string noteGlob = "*";

  auto filter(Transaction[] transactions) {
    return transactions
      .filter!(x => x.amount >= minAmount)
      .filter!(x => x.amount <= maxAmount)
      .filter!(x => x.date >= minDate)
      .filter!(x => x.date <= maxDate)
      .filter!(x => x.source.globMatch(sourceGlob))
      .filter!(x => x.dest.globMatch(destGlob))
      .filter!(x => x.note.globMatch(noteGlob));
  }
}

version (unittest) {
  import std.range     : indexed;
  import std.algorithm : equal;
  /// transactions used for all query unittests
  enum transactions = [
    Transaction(125.25 , "credit"  , "store"   , Date(2015 , 1 , 22)) , // 0
    Transaction(105.25 , "debit"   , "store"   , Date(2015 , 1 , 25)) , // 1
    Transaction(500.00 , "work"    , "savings" , Date(2015 , 2 , 2))  , // 2
    Transaction(125.25 , "savings" , "credit"  , Date(2015 , 2 , 5))  , // 3
    Transaction(25.75  , "credit"  , "store"   , Date(2014 , 8 , 12)) , // 4
    Transaction(25.75  , "debit"   , "store2"  , Date(2014 , 8 , 12)) , // 5
  ];

  /// test that result of `query` on transactions contains only transactions at `expectedIndices`
  bool queryMatch(Query query, int[] expectedIndices ...) {
    return query.filter(transactions).equal(transactions.indexed(expectedIndices));
  }
}

/// pass-through filter -- include everything
unittest {
  Query query;

  assert(query.queryMatch(0, 1, 2, 3, 4, 5));
}

/// filter by amount
unittest {
  Query query;

  query.minAmount = 105.25;
  assert(query.queryMatch(0, 1, 2, 3));

  query.maxAmount = 125.25;
  assert(query.queryMatch(0, 1, 3));
}

/// filter by date
unittest {
  Query query;

  query.minDate = Date(2015, 1, 22);
  assert(query.queryMatch(0, 1, 2, 3));

  query.maxDate = Date(2015, 2, 2);
  assert(query.queryMatch(0, 1, 2));
}

/// filter by source/dest glob
unittest {
  Query query;

  query.destGlob = "store*";
  assert(query.queryMatch(0, 1, 4, 5));

  query.sourceGlob = "debit";
  assert(query.queryMatch(1, 5));
}
