module transaction;

import std.datetime;
import jsonizer;

struct Transaction {
  mixin JsonizeMe;

  this(float amount, string source, string dest, Date date, string note = "") {
    this.amount = amount;
    this.source = source;
    this.dest   = dest;
    this.date   = date;
    this.note   = note;
  }

  @jsonize {
    float  amount; /// quantity of money that flowed
    string source; /// source the money flows out of
    string dest;   /// destination the money flows in to
    string note;   /// a textual explanation of the transaction
    string[] tags; /// tags used to categorize and group transactions
  }
  Date date; /// date that transaction occured

  // date needs special json loading instructions
  private @property {
    @jsonize("date") string _date() { return date.toISOExtString; }
    @jsonize("date") void _date(string str) { date = date.fromISOExtString(str); }
  }
}

unittest {
  Transaction trans;

  trans.amount = 20;
  trans.source = "credit_card";
  trans.dest   = "some_store";
  trans.note   = "groceries and stuff";
  trans.date   = Date(2015, 1, 4);
  trans.tags   = [ "food", "living" ];

  // is data preserved through serialization?
  auto json = trans.toJSON;
  assert(trans == json.extract!Transaction);
}
