/// read and write transaction info in persistent storage
module storage;

import std.file;
import std.path;
import std.conv;
import std.range;
import std.string;
import std.datetime;
import std.exception;
import std.algorithm;
import query;
import config;
import jsonizer;
import completion;
import transaction;

/// matches a month and year to a json file
/// storageDir/year/month.json
private enum pathFormat = "%s/%d/%d.json";

/// write newTransaction to the appropriate file
void storeTransaction(Transaction newTransaction, string storageDir) {
  auto path = dateToPath(newTransaction.date, storageDir);

  if (path.exists) { // file already exists, append transaction
    auto transactions = path.readJSON!(Transaction[]);
    transactions ~= newTransaction;
    transactions.writeJSON(path);
  }
  else {                          // no file mapped for this date yet
    if (!path.dirName.exists) {
      mkdirRecurse(path.dirName); // create parent directories as needed
    }
    [newTransaction].writeJSON(path);
  }

  // cache account names for bash completion
  if (newTransaction.dest != null) {
    cacheAccountName(newTransaction.source, storageDir);
  }

  if (newTransaction.source != null) {
    cacheAccountName(newTransaction.dest, storageDir);
  }
}

/// remove transactions that match `query` from storage
auto removeTransactions(Query query, string storageDir) {
  // load each existing path that may contain transactions in range
  auto paths = datesToPaths(query.minDate, query.maxDate, storageDir).filter!(path => path.exists);
  foreach(path ; paths) {
    // read all transactions, write back only those that don't match query criteria
    auto transactions = path.readJSON!(Transaction[]);
    auto remaining = query.removeMatching(transactions);
    remaining.writeJSON(path);
  }
}

auto loadTransactions(Date startDate, Date endDate, string storageDir) {
  if (!storageDir.exists) { return cast(Transaction[]) []; }
  return
    datesToPaths(startDate, endDate, storageDir) // for all paths covering date range
    .map!(file => file.readJSON!(Transaction[])) // extract transaction data
    .reduce!((a,b) => a ~ b);                    // flatten range of ranges
}

unittest {
 // create a temporary dir for testing, make sure to clean up when done
  auto dir = buildPath(tempDir(), "tact_unit_test");
  assert(dir != ".", "failed to create tempDir for test");
  scope(exit) {
    if (dir.exists) {
      dir.rmdirRecurse;
    }
  }

  // store some transactions
  Transaction[] expected = [
    Transaction(125.25 , "credit"  , "store"   , Date(2015 , 1 , 22)) ,
    Transaction(105.25 , "debit"   , "store"   , Date(2015 , 1 , 25)) ,
    Transaction(500.00 , "work"    , "savings" , Date(2015 , 2 , 2))  ,
    Transaction(125.25 , "savings" , "credit"  , Date(2015 , 2 , 5))  ,
  ];
  foreach(trans ; expected) {
    trans.storeTransaction(dir);
  }

  auto actual = loadTransactions(Date(2015, 1, 10), Date(2015, 2, 10), dir);
  assert(actual.length == expected.length && actual.all!(x => expected.canFind(x)));
}

private:
/// the path to the json file containing transactions for this date
string dateToPath(Date date, string storageDir) {
  return pathFormat.format(storageDir, date.year, date.month);
}

/// return the date corresponding to a path of form .../year/month.json
Date pathToDate(string path) {
  int month = path.baseName(".json").to!int;
  int year  = path.dirName.baseName.to!int;
  return Date(year, month, 1);
}

/// return true if `path` matches the expected format for storage paths
bool isValidTransactionPath(string path) {
  return 
    path.extension == ".json"        && // must be a json file
    path.baseName(".json").isNumeric && // with a numeric file name
    path.dirName.baseName.isNumeric;    // and a numeric directory above that file
}

unittest {
  auto date       = Date(2015, 5, 1);
  auto storageDir = "~/.tact";
  assert(date.dateToPath(storageDir) == "~/.tact/2015/5.json");
  assert(date.dateToPath(storageDir).pathToDate == date);
}

// return all storage paths that might contain transactions in the given date range
auto datesToPaths(Date start, Date end, string storageDir) {
  // move start to start of month, end to end of month to capture all days in month range
  start.day = 1;
  end = end.endOfMonth;
  auto interval = Interval!Date(start, end);
  return storageDir
    .dirEntries("*.json", SpanMode.depth)
    .filter!(entry => entry.isValidTransactionPath)
    .filter!(entry => interval.contains(entry.name.pathToDate));
}
