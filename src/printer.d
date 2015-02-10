module printer;

import std.conv; 
import std.range; 
import std.stdio; 
import std.string; 
import std.datetime;
import std.algorithm; 
import transaction;

string makeTable(R)(R transactions, string[] fields)
  if (isInputRange!R && is(ElementType!R : Transaction))
{
  auto columns = fields.map!(field => transactions.columnEntries(field));
  if (columns.empty) { return ""; }
  auto widths =  columns.map!(col => col.columnWidth);

  auto header = fields
    .map!(field => columnHeader(field))
    .joiner(" | ")
    .to!string;

  auto rows = transactions
    .map!(trans => fields 
        .map!(field => trans.fieldToString(field))
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
string fieldToString(Transaction transaction, string fieldName) {
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
      return transaction.date.toISOExtString;
    default:
  }
  assert(0, fieldName ~ " does not identify a transaction member");
}

/// return the title used to label a column for the given transaction field
string columnHeader(string fieldName) {
  return fieldName.capitalize;
}

/// return all string entries for a column, including the header
  auto columnEntries(R)(R transactions, string fieldName) 
if (isInputRange!R && is(ElementType!R : Transaction))
{
  return fieldName.columnHeader.only.chain(transactions.map!(x => x.fieldToString(fieldName)));
}

/// return the string length of the largest entry in the provided entries
size_t columnWidth(R)(R entries) if (isInputRange!R && is(ElementType!R == string)) {
  return entries.map!(x => x.length).reduce!max;
}

/// fieldToString
unittest {
  auto trans = Transaction(100f, "credit", "store", Date(2015, 1, 2), "stuff");
  assert(trans.fieldToString("amount") == "100.00");
  assert(trans.fieldToString("source") == "credit");
  assert(trans.fieldToString("dest") == "store");
  assert(trans.fieldToString("date") == "2015-01-02");
  assert(trans.fieldToString("note") == "stuff");
}

/// columnHeader
unittest {
  assert("amount".columnHeader == "Amount");
}

/// columnEntries and columnWidth
unittest {
  import std.algorithm : equal;

  enum transactions = [
    Transaction(125.25 , "credit"  , "store"   , Date(2015 , 1 , 22)) , // 0
    Transaction(105.25 , "debit"   , "store"   , Date(2015 , 1 , 25)) , // 1
    Transaction(500.00 , "work"    , "savings" , Date(2015 , 2 , 2))  , // 2
    Transaction(125.25 , "savings" , "credit"  , Date(2015 , 2 , 5))  , // 3
    Transaction(25.75  , "credit"  , "store"   , Date(2014 , 8 , 12)) , // 4
    Transaction(25.75  , "debit"   , "store2"  , Date(2014 , 8 , 12)) , // 5
  ];

  assert(transactions.columnEntries("amount").equal(
        [ "Amount", "125.25", "105.25", "500.00", "125.25", "25.75", "25.75" ]));

  assert(transactions.columnEntries("amount").columnWidth == "Amount".length);

  assert(transactions.columnEntries("source").equal(
        [ "Source", "credit", "debit", "work", "savings", "credit", "debit" ]));

  assert(transactions.columnEntries("source").columnWidth == "savings".length);

  assert(transactions.columnEntries("date").equal(
        [ "Date", "2015-01-22", "2015-01-25", "2015-02-02", "2015-02-05", "2014-08-12", "2014-08-12" ]));

  assert(transactions.columnEntries("date").columnWidth == "2015-02-05".length);
}

/// printTransactions
unittest {
  enum transactions = [
    Transaction(125.25 , "credit"  , "store"   , Date(2015 , 1 , 22)) , // 0
    Transaction(105.25 , "debit"   , "store"   , Date(2015 , 1 , 25)) , // 1
  ];

  assert(transactions.makeTable(["amount"]) == "Amount\n125.25\n105.25");
}
