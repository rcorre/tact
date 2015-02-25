/// filter a list of transactions by certain criteria
module query;

import std.path      : globMatch;
import std.string    : format;
import std.datetime  : Date;
import std.typecons  : Flag, Yes, No;
import std.algorithm : filter, remove, sort;
import keywords;
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

  /// sort criteria
  SortParameter sortBy = SortParameter(ParameterType.date, Yes.ascending);

  /// return a range consisting of a subset of `transactions` that meet the query criteria
  auto filter(Transaction[] transactions) {
    return transactions.filter!(x => matchesQuery(x));
  }

  /// remove elements from `transactions` that meet the query criteria
  /// mutates `transactions`, and returns a range over the mutated collection
  auto removeMatching(Transaction[] transactions) {
    return transactions.remove!(x => matchesQuery(x));
  }

  void applySort(Transaction[] transactions) {
    if (sortBy.ascending) {
      doSort!"<"(sortBy.field, transactions);
    }
    else {
      doSort!">"(sortBy.field, transactions);
    }
  }

  private:
  bool matchesQuery(Transaction trans) {
    return
      trans.amount >= minAmount          &&
      trans.amount <= maxAmount          &&
      trans.date >= minDate              &&
      trans.date <= maxDate              &&
      trans.source.globMatch(sourceGlob) &&
      trans.dest.globMatch(destGlob)     &&
      trans.note.globMatch(noteGlob);
  }

  static auto sorter(string op, string member)() {
    return mixin("(Transaction a, Transaction b) => a.%s %s b.%s".format(member, op, member));
  }

  static void doSort(string op)(ParameterType field, Transaction[] transactions) {
    final switch (field) with (ParameterType) {
      case source:
        transactions.sort!(sorter!(op, "source")());
        break;
      case dest:
        transactions.sort!(sorter!(op, "dest")());
        break;
      case date:
        transactions.sort!(sorter!(op, "date")());
        break;
      case note:
        transactions.sort!(sorter!(op, "note")());
        break;
      case amount:
        transactions.sort!(sorter!(op, "amount")());
        break;
      case sort:
      case revsort:
        break;
    }
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

  /// after using `query` to remove matching transactions, assert that only elements at
  /// `remainingIndices` remain
  bool remainsAfterRemove(Query query, int[] remainingIndices ...) {
    auto copy = transactions;
    return query.removeMatching(copy).equal(transactions.indexed(remainingIndices));
  }

  bool sortedOrderIs(Query query, int[] orderedIndices ...) {
    auto t = transactions;
    query.applySort(t);
    return t.equal(transactions.indexed(orderedIndices));
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

/// removal
unittest {
  auto tr = transactions;
  Query query;

  query.minAmount = 105.25;
  assert(query.remainsAfterRemove(4, 5));

  query.maxAmount = 125.25;
  assert(query.remainsAfterRemove(2, 4, 5));
}

/// apply sort
unittest {
  Query q;

  q.sortBy = SortParameter(ParameterType.amount, Yes.ascending);
  assert(q.sortedOrderIs(4, 5, 1, 0, 3, 2));

  q.sortBy = SortParameter(ParameterType.amount, No.ascending);
  assert(q.sortedOrderIs(2, 0, 3, 1, 4, 5));

  q.sortBy = SortParameter(ParameterType.date, Yes.ascending);
  assert(q.sortedOrderIs(4, 5, 0, 1, 2, 3));

  q.sortBy = SortParameter(ParameterType.source, No.ascending);
  assert(q.sortedOrderIs(2, 3, 1, 5, 0, 4));
}
