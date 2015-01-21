module interpreter;

import std.conv, std.getopt, std.datetime, std.regex, std.exception;
import std.c.time;
import transaction;
import printer;

void interpretCommand(string[] args) {
  interpretTransaction(args);
}

private:
void interpretTransaction(string[] args) {
  Transaction trans;

  // callback to set transaction date from string
  void setDate(string dateString) {
    trans.date = parseDate(dateString);
  }

  getopt(
    args,
    "amount", &trans.amount,
    "source", &trans.source,
    "dest",   &trans.dest,
    "date",   &setDate,
    "note",   &trans.note
  );

  //printTransaction(trans);
}

Date parseDate(string dateString) {
  auto rx    = regex(r"(\d+)/(\d+)/(\d+)");
  auto match = dateString.match(rx);
  enforce(match, "failed to parse date " ~ dateString);

  int month = match.captures[1].to!int;
  int day   = match.captures[2].to!int;
  int year  = match.captures[3].to!int;

  year = (year < 100) ? year + 2000 : year;

  return Date(year, month, day);
}

unittest {
  auto date = parseDate("04/22/15");
  assert(date.month == 4);
  assert(date.day == 22);
  assert(date.year == 2015);
}
