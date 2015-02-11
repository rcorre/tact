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
  Query params;
  foreach(pair ; args.drop(1).chunks(2)) {
    string keyword = pair[0];
    string value   = pair[1];

    // try to reference provided keyword to a instruction defined in the config
    enforce(keyword in cfg.keywords, keyword ~ " is not a known keyword");

    final switch (cfg.keywords[keyword]) with (CommandKeyword) {
      case source:
        params.sourceGlob = value;
        break;
      case dest:
        params.destGlob = value;
        break;
      case note:
        params.noteGlob = value;
        break;
      case amount:
        value.assignMinMax!(x => x.to!float)(cfg, params.minAmount, params.maxAmount);
        break;
      case date:
        value.assignMinMax!(x => Date.fromISOExtString(x))(cfg, params.minDate, params.maxDate);
        break;
      case query: // should not appear after first argument
        enforce(0, "duplicate keyword " ~ keyword ~ " in params command");
        break;
    }
  }
  return params;
}

private:
/// assign `min` and `max` based on a `input`, which may represent a range of values
/// if `input` is a single value, assign `convert(input)` to `min` and `max`
/// if `input` is a range, split it and assign the first part to `min`, the second part to `max`
void assignMinMax(alias convert, T)(string input, Config cfg, out T min, out T max)
  if (is(typeof(convert(string.init)) : T))
{
  auto vals = input.splitRange!(T, convert)(cfg.rangeDelimiter);
  switch(vals.length) {
    case 1: // only one value, use as both min and max (exact range)
      min = max = vals[0];
      break;
    case 2: // two values, set min and max to encompass requested range
      min = vals[0];
      max = vals[1];
      break;
    default:
      enforce(0, input ~ " is not a valid range");
  }
}

/// split an argument representing a range into an array containing the range values
T[] splitRange(T, alias convert)(string str, string delimiter)
  if (is(typeof(convert(string.init)) : T))
{
  return str
    .splitter(delimiter)   // split on range delimiter
    .map!(x => convert(x)) // apply provided conversion function to each element
    .array;                // return as array
}

/// splitRange
unittest {
  auto r1 = "125".splitRange!(int, s => s.to!int)("-");
  auto r2 = "125-250".splitRange!(int, s => s.to!int)("-");
  assert(r1.length == 1 && r1[0] == 125);
  assert(r2.length == 2 && r2[0] == 125 && r2[1] == 250);

  r1 = "125".splitRange!(int, s => s.to!int)("..");
  r2 = "125..250".splitRange!(int, s => s.to!int)("..");
  assert(r1.length == 1 && r1[0] == 125);
  assert(r2.length == 2 && r2[0] == 125 && r2[1] == 250);
}

/// assignMinMax
unittest {
  struct S { float minVal; float maxVal; }
  S s;
  Config cfg; // default config

  auto input = "500.50";
  input.assignMinMax!(x => x.to!float)(cfg, s.minVal, s.maxVal);
  assert(s.minVal == 500.50f && s.maxVal == 500.50f);

  input = "220,500.50";
  input.assignMinMax!(x => x.to!float)(cfg, s.minVal, s.maxVal);
  assert(s.minVal == 220f && s.maxVal == 500.50f);
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
  assert(args.parseQuery(cfg) == Query.init); // should be default query

  args = [ "list", "amount", "250,525", "from", "*bank*" , "on", "2015-05-01,2015-05-22"];

  // check command type
  assert(args.commandType(cfg) == CommandType.query);
  auto query = args.parseQuery(cfg);
  assert(query.minAmount  == 250f);
  assert(query.maxAmount  == 525f);
  assert(query.minDate    == Date(2015, 5, 1));
  assert(query.maxDate    == Date(2015, 5, 22));
  assert(query.sourceGlob == "*bank*");
  assert(query.destGlob   == "*");
}
