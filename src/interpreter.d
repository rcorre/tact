module interpreter;

import std.conv; 
import std.range; 
import std.array;
import std.datetime; 
import std.exception;
import config;
import command;
import query;
import transaction;

/// determine the type of command represented by the given input `args`
CommandType commandType(string[] args, Config cfg) {
  try {
    args[0].to!float;
    return CommandType.create;
  }
  catch {
    return CommandType.query;
  }
}

/// translate `args` into a transaction using the settings defined by `cfg`
Transaction parseTransaction(string[] args, Config cfg) {
  assert(args.commandType(cfg) == CommandType.create, args.to!string ~ " is not a create command");

  // default construct transaction
  Transaction trans;
  trans.amount = args[0].to!float;          // amount is leading numeric value
  trans.date   = cast(Date) Clock.currTime; // default date to today

  // populate transaction fields from remaining args, which come in keyword/value pairs
  foreach(pair ; args.drop(1).chunks(2)) {
    string keyword = pair[0];
    string value   = pair[1];

    // try to reference provided keyword to a instruction defined in the config
    enforce(keyword in cfg.keywords, keyword ~ " is not a known keyword");

    final switch (cfg.keywords[keyword]) with (CommandKeyword) {
      case source:
        trans.source = value;
        break;
      case dest:
        trans.dest = value;
        break;
      case date:
        trans.date = Date.fromISOExtString(value);
        break;
      case note:
        trans.note = value;
        break;
      case query:
      case amount:
        enforce(0, keyword ~ " is not a valid keyword for a transaction command");
        break;
    }
  }

  return trans;
}

Query parseQuery(string[] args, Config cfg) {
  Query query;
  foreach(pair ; args.drop(1).chunks(2)) {
    string keyword = pair[0];
    string value   = pair[1];

    // try to reference provided keyword to a instruction defined in the config
    enforce(keyword in cfg.keywords, keyword ~ " is not a known keyword");

    final switch (cfg.keywords[keyword]) with (CommandKeyword) {
      case amount:
        break;
      case source:
        break;
      case dest:
        break;
      case date:
        break;
      case note:
        break;
      case query: // already handled to trigger query command
        enforce(0, "duplicate keyword " ~ keyword ~ " in query command");
        break;
    }
  }
  return query;
}

private:
/// split an argument representing a range into an array containing the range values 
T[] splitRange(T, alias convert)(string str, Config cfg) if (is(typeof(convert(string.init)) : T)) {
  return str
    .splitter(cfg.rangeDelimiter) // split on range delimiter
    .map!(x => convert(x))        // apply provided conversion function to each element
    .array;                       // return as array
}

unittest {
  Config cfg; // default config
  assert(cfg.rangeDelimiter == "-", "unexpected default range delimiter in unittest");

  auto r1 = "125".splitRange!(int, s => s.to!int)(cfg);
  auto r2 = "125-250".splitRange!(int, s => s.to!int)(cfg);
  assert(r1.length == 1 && r1[0] == 125); 
  assert(r2.length == 2 && r2[0] == 125 && r2[1] == 250); 

  // try a custom delimiter
  cfg.rangeDelimiter = ",";

  r1 = "125".splitRange!(int, s => s.to!int)(cfg);
  r2 = "125,250".splitRange!(int, s => s.to!int)(cfg);
  assert(r1.length == 1 && r1[0] == 125); 
  assert(r2.length == 2 && r2[0] == 125 && r2[1] == 250); 
}

/// parse a simple transaction
unittest {
  // test with default config and some mock arguments
  auto cfg = Config.load("nonexistantpath");
  auto args = [ "100", "from", "savings", "to", "credit" ];

  // check command type
  assert(args.commandType(cfg) == CommandType.create);

  // parse transaction
  auto trans = args.parseTransaction(cfg);
  assert(trans.amount == 100);
  assert(trans.source == "savings");
  assert(trans.dest   == "credit");
  assert(trans.date   == cast(Date) Clock.currTime); // date should have defaulted to current time
}

/// parse a more complex transaction
unittest {
  // test with default config and some mock arguments
  auto cfg = Config.load("nonexistantpath");
  auto args = [ "98.25", "to", "store", "on", "2015-08-04", "for", "stuff" ];

  // check command type
  assert(args.commandType(cfg) == CommandType.create);

  // parse transaction
  auto trans = args.parseTransaction(cfg);
  assert(trans.amount == 98.25f);
  assert(trans.source is null);
  assert(trans.dest   == "store");
  assert(trans.date   == Date(2015, 8, 4));
  assert(trans.note   == "stuff");
}

/// parse a query
unittest {
  // test with default config and some mock arguments
  auto cfg = Config.load("nonexistantpath");
  auto args = [ "list" ]; // just list everythign

  // check command type
  assert(args.commandType(cfg) == CommandType.query);
}
