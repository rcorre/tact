module transaction;

import std.datetime;

struct Transaction {
  float  amount; /// quantity of money that flowed
  string source; /// source the money flows out of
  string dest;   /// destination the money flows in to
  Date   date;   /// date that transaction occured
  string note;   /// a textual explanation of the transaction
}
