/// read and write transaction info in persistent storage
module storage;

import std.file;
import std.path;
import std.range;
import std.string;
import std.datetime;
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

Transaction loadTransactions(Date startDate, Date endDate, string storageDir) {
  return Transaction();
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
  Transaction trans;
  trans.amount = 125.25;
  trans.source = "credit_card";
  trans.dest = "grocery_store";
  trans.note = "food and stuff";
  trans.date = Date(2015, 5, 21);

  storeTransaction(trans, dir);
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
