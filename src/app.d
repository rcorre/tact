import std.conv  : to;
import std.stdio : writeln;
import config;
import storage;
import command;
import printer;
import completion;
import interpreter;

version (Windows) {
  static assert(0, "don't know where windows home dir is!");
}
else {
  private enum configPath = "~/.tactrc";
}

void main(string[] args) {
  // load config file, or use default config if not available
  auto cfg = Config.load(configPath);

  // parse input and execute command
  auto input = args[1 .. $]; // strip executable name
  auto cmdType = input.commandType(cfg);

  final switch (cmdType) with (CommandType) {
    case create:
      auto trans = input.parseTransaction(cfg);
      storeTransaction(trans, cfg.storageDir);
      break;
    case query:
      auto query        = input.parseQuery(cfg);
      auto transactions = loadTransactions(query.minDate, query.maxDate, cfg.storageDir);
      auto results      = query.filter(transactions);
      writeln(results.makeTable(["date", "source", "dest", "amount", "note" ], cfg));
      break;
    case complete:
      // the args should look like "_complete <cword> bin/tact <args...>"
      assert(input.length >= 3, "improper arguments provided to completion function");
      int cword = input[1].to!int;    // cword is first arg after complete
      string[] words = input[3 .. $]; // strip duplicate executable name
      writeln(getCompletions(cword, words, cfg));
  }
}
