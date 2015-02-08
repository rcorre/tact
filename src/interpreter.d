module interpreter;

import std.conv, std.range, std.datetime, std.exception;
import config;
import command;
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
      case amount:
        trans.amount = value.to!float;
        break;
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
    }
  }

  return trans;
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
