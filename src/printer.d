/// present groups of transactions in an easily readable tabular format
module printer;

import std.conv;
import std.range;
import std.stdio;
import std.string;
import std.datetime;
import std.algorithm;
import dates;
import config;
import transaction;

/// build a readable string table containing the given `fields` of `transactions`.
/// Params:
///   transactions = transactions to include in table
///   fields = names of transaction fields to include, in order
/// Returns: a string table with a column for each field and row for each transaction
string makeTable(R)(R transactions, string[] fields, Config cfg)
  if (isInputRange!R && is(ElementType!R : Transaction))
{
  auto columns = fields.map!(field => transactions.columnEntries(field, cfg));
  if (columns.empty) { return ""; }
  auto widths =  columns.map!(col => col.columnWidth);

  auto header = fields
    .map!(field  => columnHeader(field))
    .zip(widths)
    .map!(pair => pair[0].center(pair[1]))
    .joiner(" | ")
    .to!string;

  auto rows = transactions
    .map!(trans => fields
        .map!(field => trans.fieldToString(field, cfg))
        .zip(widths)
        .map!(pair => pair[0].rightJustify(pair[1]))
        .joiner(" | "))
    .joiner("\n")
    .to!string;

  return header ~ "\n" ~ rows;
}

private:
enum amountFormat = "%.2f";

/// return `transaction`.`fieldName` as a string
string fieldToString(Transaction transaction, string fieldName, Config cfg) {
  switch (fieldName) {
    case "amount":
      return amountFormat.format(transaction.amount);
    case "source":
      return transaction.source;
    case "dest":
      return transaction.dest;
    case "note":
      return transaction.note;
    case "date":
      return transaction.date.dateToString(cfg.dateFormat);
    default:
  }
  assert(0, fieldName ~ " does not identify a transaction member");
}

/// return the title used to label a column for the given transaction field
string columnHeader(string fieldName) {
  return fieldName.capitalize;
}

/// return all string entries for a column, including the header
auto columnEntries(R)(R transactions, string fieldName, Config cfg)
if (isInputRange!R && is(ElementType!R : Transaction))
{
  return fieldName.columnHeader.only.chain(transactions.map!(x => x.fieldToString(fieldName, cfg)));
}

/// return the string length of the largest entry in the provided entries
size_t columnWidth(R)(R entries) if (isInputRange!R && is(ElementType!R == string)) {
  return entries.map!(x => x.length).reduce!max;
}

/// fieldToString
unittest {
  Config cfg; // default config
  auto trans = Transaction(100f, "credit", "store", Date(2015, 1, 2), "stuff");
  assert(trans.fieldToString("amount", cfg) == "100.00");
  assert(trans.fieldToString("source", cfg) == "credit");
  assert(trans.fieldToString("dest", cfg)   == "store");
  assert(trans.fieldToString("date", cfg)   == "01/02/15");
  assert(trans.fieldToString("note", cfg)   == "stuff");
}

/// columnHeader
unittest {
  assert("amount".columnHeader == "Amount");
}

/// columnEntries and columnWidth
unittest {
  import std.algorithm : equal;

  Config cfg; // default config

  enum transactions = [
    Transaction(125.25 , "credit"  , "store"   , Date(2015 , 1 , 22)) , // 0
    Transaction(105.25 , "debit"   , "store"   , Date(2015 , 1 , 25)) , // 1
    Transaction(500.00 , "work"    , "savings" , Date(2015 , 2 , 2))  , // 2
    Transaction(125.25 , "savings" , "credit"  , Date(2015 , 2 , 5))  , // 3
    Transaction(25.75  , "credit"  , "store"   , Date(2014 , 8 , 12)) , // 4
    Transaction(25.75  , "debit"   , "store2"  , Date(2014 , 8 , 12)) , // 5
  ];

  assert(transactions.columnEntries("amount", cfg).equal(
        [ "Amount", "125.25", "105.25", "500.00", "125.25", "25.75", "25.75" ]));

  assert(transactions.columnEntries("amount", cfg).columnWidth == "Amount".length);

  assert(transactions.columnEntries("source", cfg).equal(
        [ "Source", "credit", "debit", "work", "savings", "credit", "debit" ]));

  assert(transactions.columnEntries("source", cfg).columnWidth == "savings".length);

  assert(transactions.columnEntries("date", cfg).equal(
        [ "Date", "01/22/15", "01/25/15", "02/02/15", "02/05/15", "08/12/14", "08/12/14" ]));

  assert(transactions.columnEntries("date", cfg).columnWidth == "02/05/15".length);
}

/// printTransactions
unittest {
  import std.conv : to;
  import std.algorithm : joiner;
  enum transactions = [
    Transaction(125.25 , "credit"  , "store"   , Date(2015 , 1 , 22)) , // 0
    Transaction(105.25 , "debit"   , "store"   , Date(2015 , 1 , 25)) , // 1
    Transaction(500.00 , "work"    , "savings" , Date(2015 , 2 , 2))  , // 2
  ];

  Config cfg; // default config

  assert(transactions.makeTable(["amount", "source", "date"], cfg) == [
    "Amount | Source |   Date  ",
    "125.25 | credit | 01/22/15",
    "105.25 |  debit | 01/25/15",
    "500.00 |   work | 02/02/15",
  ].joiner("\n").to!string);

  assert(transactions.makeTable(["date", "amount", "dest"], cfg) == [
    "  Date   | Amount |  Dest  ",
    "01/22/15 | 125.25 |   store",
    "01/25/15 | 105.25 |   store",
    "02/02/15 | 500.00 | savings",
  ].joiner("\n").to!string);
}
