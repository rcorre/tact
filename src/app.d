import std.conv  : to;
import std.stdio : write, writeln, readln;
import std.string : chomp, toLower;
import std.exception : enforce;
import config;
import storage;
import printer;
import keywords;
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
    // load config file, or use default config if not available
    auto cfg = Config.load(configPath);

    // parse args and execute command
    args = args[1 .. $]; // strip executable name
    auto opType = operationType(args, cfg);

    final switch (opType) with (OperationType) {
      case create:
        auto trans = args.parseTransaction(cfg);
        storeTransaction(trans, cfg.storageDir);
        break;
      case query:
        auto query        = args.parseQuery(cfg);
        auto transactions = loadTransactions(query.minDate, query.maxDate, cfg.storageDir);
        auto results      = query.filter(transactions);
        writeln(results.makeTable(["date", "source", "dest", "amount", "note" ], cfg));
        break;
      case remove:
        auto query        = args.parseQuery(cfg);
        auto transactions = loadTransactions(query.minDate, query.maxDate, cfg.storageDir);
        auto results      = query.filter(transactions);
        writeln("The following transactions will be removed:");
        writeln(results.makeTable(["date", "source", "dest", "amount", "note" ], cfg));
        write("OK (y/n)?: ");
        string response = readln().chomp.toLower;
        if (response == "y" || response == "yes") {
          removeTransactions(query, cfg.storageDir);
        }
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
