module printer;

import std.stdio, std.algorithm, std.conv, std.string, std.datetime;
import transaction;

void printTransaction(Transaction transaction) {
  writeln(transaction.toString(" | "));
}

string toString(Transaction transaction, string fieldSep) {
  string[] fields = [
    transaction.date.to!string,
    "%.2f".format(transaction.amount),
    transaction.source,
    transaction.dest,
    transaction.note
  ];

  return fields.joiner(fieldSep).to!string;
}

unittest {
  Transaction trans;
  trans.amount = 100.50;
  trans.source = "visa";
  trans.dest   = "earthfare";
  trans.date   = Date(2015, 1, 15);
  trans.note   = "groceries and stuff";

  assert(trans.toString(" | ") == "2015-Jan-15 | 100.50 | visa | earthfare | groceries and stuff");
}
