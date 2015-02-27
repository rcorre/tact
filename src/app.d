import std.conv  : to;
import std.math  : isNaN;
import std.range : chain;
import std.array : array;
import std.stdio : write, writeln, writefln, readln;
import std.string : chomp, toLower;
import usage;
import config;
import storage;
import printer;
import keywords;
import jsonizer;
import completion;
import interpreter;

version (Windows) {
  static assert(0, "don't know where windows home dir is!");
}
else {
  private enum configPath = "~/.tactrc";
}

void main(string[] args) {
  try {
    if (args.length <= 1) {
      printUsage();
      return;
    }

    // load config file, or use default config if not available
    auto cfg = Config.load(configPath);

    // parse args and execute command
    args = args[1 .. $]; // strip executable name
    auto opType = operationType(args, cfg);

    final switch (opType) with (OperationType) {
      case create:
        auto trans = args.parseTransaction(cfg);
        if (trans.amount.isNaN || trans.source is null || trans.dest is null) {
          writeln("A transaction must specify an amount, source, and dest");
        }
        else {
          storeTransaction(trans, cfg.storageDir);
        }
        break;
      case query:
        auto query        = args.parseQuery(cfg);
        auto transactions = loadTransactions(query.minDate, query.maxDate, cfg.storageDir);
        auto results      = query.filter(transactions).array;
        query.applySort(results);
        writeln(results.makeTable(["date", "source", "dest", "amount", "note" ], cfg));
        break;
      case remove:
        auto query        = args.parseQuery(cfg);
        auto transactions = loadTransactions(query.minDate, query.maxDate, cfg.storageDir);
        auto results      = query.filter(transactions).array;
        query.applySort(results);
        writeln("The following transactions will be removed:");
        writeln(results.makeTable(["date", "source", "dest", "amount", "note" ], cfg));
        write("OK (y/n)?: ");
        string response = readln().chomp.toLower;
        if (response == "y" || response == "yes") {
          removeTransactions(query, cfg.storageDir);
        }
        break;
      case edit:
        auto query = args.parseQuery(cfg);
        bool edited = editTransactions(query, cfg);
        if (edited) {
          writeln("Edit successful");
        }
        else {
          writeln("Edit operation cancelled");
        }
        break;
      case balance:
        if (args.length == 0) {
          writeln("Expected the name of an account to balance");
          break;
        }
        float balance;
        auto transactions = loadAccountBalance(args[1], cfg.storageDir, balance);
        writeln(transactions.makeTable(["date", "source", "dest", "amount", "note" ], cfg));
        writefln("Balance: %.2f", balance);
        break;
      case help:
        printUsage();
        break;
      case complete:
        // the args should look like "_complete <cword> bin/tact <args...>"
        assert(args.length >= 3, "improper arguments provided to completion function");
        int cword = args[1].to!int;    // cword is first arg after complete
        string[] words = args[3 .. $]; // strip duplicate executable name
        writeln(getCompletions(cword, words, cfg));
        break;
    }
  }
  catch (Exception ex) {
    writeln(ex.msg);
  }
}
