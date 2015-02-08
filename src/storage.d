/// read and write transaction info in persistent storage
module storage;

import std.file;
import std.path;
import std.range;
import std.string;
import std.datetime;
import std.algorithm;
import config;
import jsonizer;
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
}

auto loadTransactions(Date startDate, Date endDate, string storageDir) {
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

unittest {
  auto date       = Date(2015, 5, 1);
  auto storageDir = "~/.tact";
  assert(dateToPath(date, storageDir) == "~/.tact/2015/5.json");
}

auto datesToPaths(Date start, Date end, string storageDir) {
  // find every month/year combo to cover all dates between start and end
  return start
    .recurrence!((a,n) => a[n - 1].add!"months"(1)) // enumerate months from start
    .until!(date => date >= end.endOfMonth)         // up through end month/year
    .map!(date => dateToPath(date, storageDir));    // and map to paths
}

unittest {
  enum storageDir = "~/.tact";
  auto start = Date(2014, 11, 14);
  auto end   = Date(2015,  2, 6);
  enum expected = [
    "~/.tact/2014/11.json",
    "~/.tact/2014/12.json",
    "~/.tact/2015/1.json",
    "~/.tact/2015/2.json",
  ];
  assert(datesToPaths(start, end, storageDir).equal(expected));
}
