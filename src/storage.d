/// read and write transaction info in persistent storage
module storage;

import std.file;
import std.path;
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
  else {                        // no file mapped for this date yet
    if (!path.dirName.exists) {
      mkdirRecurse(path);       // create parent directories as needed
    }
    [newTransaction].writeJSON(path);
  }
}

unittest {
  auto dir = tempDir(); // create a temporary dir for testing
  assert(dir != ".", "failed to create tempDir for test");
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
