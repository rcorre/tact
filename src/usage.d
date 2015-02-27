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

void printOperationUsage(OperationType op, Config cfg) {
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
