module interpreter;

import std.getopt, std.datetime, std.exception;
import printer;
import transaction;

void interpretCommand(string[] args) {
  interpretTransaction(args);
}

private:
void interpretTransaction(string[] args) {
  Transaction trans;

  // callback to set transaction date from string
  void setDate(string opt, string dateString) {
    trans.date = Date.fromISOExtString(dateString);
  }

  getopt(
    args,
    "amount", &trans.amount,
    "source", &trans.source,
    "dest",   &trans.dest,
    "date",   &setDate,
    "note",   &trans.note
  );

  printTransaction(trans);
}
