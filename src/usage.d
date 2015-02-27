/// implements the `help` command, which provides usage instructions on the command line
module usage;

import std.stdio : writeln, writefln;
import config;
import keywords;

void printUsage() {
  writeln("usage: tact <command> [<args>]");
  writeln();
  writeln("The available commands are:");
  foreach(pair ; opDescriptions) {
    writefln("%-8s : %s", pair[0], pair[1]);
  }
  writeln();
  writeln("Use help <command> for command specific-usage information");
}

void printOperationUsage(OperationType op, string keywordUsed) {
  string argString;
  final switch (op) with (OperationType) {
    case create:
      argString = "<amount> [from <source>] [to <dest>] [on <date>] [for <note>]";
      break;
    case query:
      argString = "[amount <amount>] [from <source>] [to <dest>] [on <date>] [for <note>]";
      break;
    case remove:
      argString = "[amount <amount>] [from <source>] [to <dest>] [on <date>] [for <note>]";
      break;
    case edit:
      argString = "[amount <amount>] [from <source>] [to <dest>] [on <date>] [for <note>]";
      break;
    case balance:
      argString = "<account_name>";
      break;
    case help:
      argString = "[<command>]";
      break;
    case complete:
      argString = "WORDS";
      break;
  }

  writefln("usage: tact %s %s", keywordUsed, argString);
}

private:
immutable opDescriptions = [
  [ "add"    , "create and store a new transaction" ],
  [ "list"   , "print transactions matching a query" ],
  [ "remove" , "remove transactions matching a query" ],
  [ "edit"   , "modify transactions matching a query" ],
  [ "balance", "calculate the current balance of an account" ],
  [ "help"   , "print out usage information" ]
];
