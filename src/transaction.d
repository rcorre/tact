module transaction;

import std.datetime;
import jsonizer;

struct Transaction {
  mixin JsonizeMe;

  @jsonize {
    float  amount; /// quantity of money that flowed
    string source; /// source the money flows out of
    string dest;   /// destination the money flows in to
    string note;   /// a textual explanation of the transaction
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

  // is data preserved through serialization?
  auto json = trans.toJSON;
  assert(trans == json.extract!Transaction);
}
