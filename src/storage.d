/// read and write transaction info in persistent storage
module storage;

import std.file;
import std.path;
import std.conv;
import std.range;
import std.array : array, split;
import std.string;
import std.datetime;
import std.process : wait, spawnProcess;
import std.algorithm;
import query;
import config;
import jsonizer;
import completion;
import transaction;

/// matches a month and year to a json file: storageDir/year/month.json
private enum pathFormat = "%s/%d/%d.json";
/// temporary file name used to edit transactions
private enum editFileName = "tact_edit.json";

class StorageException : Exception {
  this(string message, string[] params ...) {
    super("Storage failure:\n" ~ msg.format(params));
  }
}

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

void storeTransactions(Transaction[] newTransactions, string storageDir) {
  foreach(trans ; newTransactions) {
    storeTransaction(trans, storageDir);
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

/// spawn an editor to modify transactions matching `query`
/// returns `true` if transactions successfully edited
bool editTransactions(Query query, Config cfg) {
  // construct json array containing only transactions matching the query
  auto toEdit = query.filter(loadTransactions(query.minDate, query.maxDate, cfg.storageDir));

  // place json in temp file
  auto path = buildPath(tempDir(), editFileName);
  scope(exit) { path.remove(); }
  toEdit.array.writeJSON(path);

  // open temp file with editor
  auto pid = spawnProcess(["vim", path]);
  if (pid.wait == 0) {
    try {
      auto result = path.readJSON!(Transaction[]);
      removeTransactions(query, cfg.storageDir);
      storeTransactions(result, cfg.storageDir);
      return true;
    }
    catch {
      throw new StorageException("Edit cancelled, invalid json:\n%s", path.readText);
    }
  }
  return false;
}

auto loadTransactions(Date startDate, Date endDate, string storageDir) {
  if (!storageDir.exists) { return cast(Transaction[]) []; }
  return
    datesToPaths(startDate, endDate, storageDir) // for all paths covering date range
    .map!(file => file.readJSON!(Transaction[])) // extract transaction data
    .reduce!((a,b) => a ~ b);                    // flatten range of ranges
}

auto loadAccountBalance(string accountName, string storageDir, out float balance) {
  auto allTransactions = loadTransactions(Date.min, Date.max, storageDir);

  Query incomingQuery, outgoingQuery;
  // all transactions with this account as the source are outgoing
  outgoingQuery.sourceGlob = accountName;
  // all transactions with this account as the destination are incoming
  incomingQuery.destGlob   = accountName;

  auto outgoing = outgoingQuery.filter(allTransactions);
  auto incoming = incomingQuery.filter(allTransactions);

  auto inflow  = incoming.map!(x => x.amount).sum;
  auto outflow = outgoing.map!(x => x.amount).sum;
  balance = inflow - outflow;

  return incoming.array ~ outgoing.array;
}

/// `loadTransactions`
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

/// `loadAccountBalance`
unittest {
  import std.math : approxEqual;
  import std.range : indexed;
 // create a temporary dir for testing, make sure to clean up when done
  auto dir = buildPath(tempDir(), "tact_unit_test");
  assert(dir != ".", "failed to create tempDir for test");
  scope(exit) {
    if (dir.exists) {
      dir.rmdirRecurse;
    }
  }

  // store some transactions
  Transaction[] transactions = [
    Transaction(105.25 , "credit"  , "store"   , Date(2015 , 1 , 25)) ,
    Transaction(125.25 , "credit"  , "store"   , Date(2015 , 1 , 22)) ,
    Transaction(500.00 , "work"    , "savings" , Date(2015 , 2 , 2))  ,
    Transaction(125.25 , "savings" , "credit"  , Date(2015 , 2 , 5))  ,
  ];
  foreach(trans ; transactions) {
    trans.storeTransaction(dir);
  }

  float balance;
  auto actual = loadAccountBalance("credit", dir, balance);

  auto expected = transactions.indexed([0, 1, 3]);
  assert(actual.walkLength == expected.walkLength && actual.all!(x => expected.canFind(x)));
  assert(balance.approxEqual(125.25 - (125.25 + 105.25)));
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

string[] constructEditProcessArgs(string fileName, string editCmd) {
  try {
    string argString = editCmd.format(fileName);
    return argString.split(" ");
  }
  catch {
    throw new StorageException("Failed to open editor.\nCommand format: %s\nFilename: %s",
        editCmd, fileName);
  }
}

/// `constructEditProcessArgs`
unittest {
  assert(constructEditProcessArgs("some/file.json", "gvim %s") == [ "gvim", "some/file.json" ]);

  assert(constructEditProcessArgs("a/b.json", "someeditor -e %s --otheroption") ==
      [ "someeditor", "-e", "a/b.json", "--otheroption" ]);
}
