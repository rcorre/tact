/// implements the `help` command, which provides usage instructions on the command line
module usage;

import std.stdio  : writeln, writefln;
import config;
import keywords;

void printUsage() {
  writeln("usage: tact <command> [<args>]");
  writeln();
  writeln("The available commands are:");
  printOpDescriptions();
  writeln();
  writeln("Use help <command> for command specific-usage information");
}

void printOperationUsage(OperationType op, string keywordUsed) {
  string argString, details;
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
  printQueryDescriptions();
  writeln();
  writeln("for glob-style arguments, make sure to escape the glob from your shell");
  writeln(`    for example, tact list note "*groceries*",`);
  writeln("for range-style arguments, the following forms are supported");
  writeln("    lower-upper : matches any value 'val' such that upper <= val <= upper");
  writeln("    -upper      : matches any value 'val' such that val <= upper");
  writeln("    lower-      : matches any value 'val' such that val >= lower");
}

private:
immutable fmt = "%-8s : %s"; // keyword : description

void printDescription(T)(T keywordType, string description) {
  writefln(fmt, defaultKeyword(keywordType), description);
}

void printOpDescriptions() {
  with(OperationType) {
    printDescription(create , "create and store a new transaction");
    printDescription(query  , "print transactions matching a query");
    printDescription(remove , "remove transactions matching a query");
    printDescription(edit   , "modify transactions matching a query");
    printDescription(balance, "calculate the current balance of an account");
    printDescription(help   , "print out usage information");
  }
}

void printFieldDescriptions() {
  with(ParameterType) {
    printDescription(amount, `set the transaction amount [required]`);
    printDescription(source, `set the transaction source [default=""]`);
    printDescription(dest  , `set the transaction dest   [default=""]`);
    printDescription(date  , `set the transaction date   [default=today]`);
    printDescription(note  , `assign a descriptive note  [default=""]`);
    printDescription(tags  , `comma-separated tag list   [default=""]`);
  }
}

void printQueryDescriptions() {
  with(ParameterType) {
    printDescription(amount, `match transaction amount - single value or range`);
    printDescription(date  , `match transaction date   - single value or range`);
    printDescription(source, `match transaction source - supports glob matching`);
    printDescription(dest  , `match transaction dest   - supports glob matching`);
    printDescription(note  , `match transaction note   - supports glob matching`);
    printDescription(tags  , `match transaction tags   - comma-separated list`);
  }
}
