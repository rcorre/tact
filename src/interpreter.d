module interpreter;

import std.conv      : to;
import std.range     : chunks, drop, empty;
import std.array     : array;
import std.string    : isNumeric, format;
import std.datetime  : Date, Clock;
import std.exception : enforce;
import std.algorithm : findSplit, startsWith;
import query;
import dates;
import config;
import keywords;
import transaction;

/// thrown when command line options cannot be interpreted
class InterpreterException : Exception {
  /// construct an exception from the invalid keyword `input`
  this(string msg, string params ...) {
    super("Interpreter failure:\n" ~ msg.format(params));
  }
}

/// determine the type of command represented by the given input `args`
OperationType operationType(string[] args, Config cfg) {
  string op = args[0];
  if (op.isNumeric) {
    return OperationType.create;
  }
  return parseOperationKeyword(op, cfg.aliases);
}

/// translate `args` into a transaction using the settings defined by `cfg`
Transaction parseTransaction(string[] args, Config cfg) {
  assert(args.operationType(cfg) == OperationType.create, args.to!string ~ " is not a create command");

  // default construct transaction
  Transaction trans;

  // if first arg is a number, use that to set transaction amount
  if (args[0].isNumeric) {
    trans.amount = args[0].to!float;
  }

  trans.date   = cast(Date) Clock.currTime; // default date to today

  // drop first arg, it is either amount or add keyword
  // populate transaction fields from remaining args, which come in keyword/value pairs
  foreach(pair ; args.drop(1).chunks(2)) {
    string keyword = pair[0];
    string value   = pair[1];

    // try to reference provided keyword to a instruction defined in the config
    final switch (parseParameterKeyword(keyword, cfg.aliases)) with (ParameterType) {
      case source:
        trans.source = value;
        break;
      case dest:
        trans.dest = value;
        break;
      case date:
        trans.date = value.stringToDate(cfg.dateFormat);
        break;
      case note:
        trans.note = value;
        break;
      case amount:
        trans.amount = value.to!float;
        break;
      case sort:
      case revsort:
        break;
    }
  }

  return trans;
}

Query parseQuery(string[] args, Config cfg) {
  Query params;
  foreach(pair ; args.drop(1).chunks(2)) {
    if (pair.length == 1) {
      throw new InterpreterException("no argument provided for keyword %s", pair[0]);
    }
    string keyword = pair[0];
    string value   = pair[1];

    final switch (parseParameterKeyword(keyword, cfg.aliases)) with (ParameterType) {
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
        value.assignMinMax!(x => x.to!float)(cfg.rangeDelimiter, params.minAmount, params.maxAmount);
        break;
      case date:
        value.assignMinMax!(x => x.stringToDate(cfg.dateFormat))(cfg.rangeDelimiter, params.minDate,
            params.maxDate);
        break;
      case sort:
        params.sortBy = SortParameter(parseParameterKeyword(value, cfg.aliases), Yes.ascending);
        break;
      case revsort:
        params.sortBy = SortParameter(parseParameterKeyword(value, cfg.aliases), No.ascending);
        break;
    }
  }
  return params;
}

private:
/// assign `min` and `max` based on a `input`, which may represent a range of values
/// if `input` is a single value, assign `convert(input)` to `min` and `max`
/// if `input` is a range, split it and assign the first part to `min`, the second part to `max`
/// if `input` starts with range delimiter, range is [T.min, input]
/// if `input` ends with range delimiter, range is [input, T.max]
void assignMinMax(alias convert, T)(string input, string delimiter, out T low, out T high)
  if (is(typeof(convert(string.init)) : T) && is(typeof(T.min)) && is(typeof(T.max)))
{
  static if (is(T == float)) {
    low  = -float.max;
    high = float.max;
  }
  else {
    low = T.min;
    high = T.max;
  }

  // get split of the form [ prefix , delimiter , postfix ]
  auto split = input.findSplit(delimiter);
  if (split[0].empty) { // prefix is empty, range is [ T.min, postfix ]
    high = convert(split[2]);
  }
  else if (split[1].empty) { // no delimiter, use value for min and max
    low = high = convert(split[0]);
  }
  else if (split[2].empty) { // postfix is empty, range is [ prefix, T.max ]
    low = convert(split[0]);
  }
  else { // both min and max given
    low  = convert(split[0]);
    high = convert(split[2]);
  }
}

/// `assignMinMax`
unittest {
  Config cfg; // default config

  bool test(string input, int expectedMin, int expectedMax, string rangeDelimiter = "-") {
    int lo, hi;
    assignMinMax!(x => x.to!int)(input, rangeDelimiter, lo, hi);
    return lo == expectedMin && hi == expectedMax;
  }

  // test default delimiter "-"
  assert(test("125"    , 125    , 125));
  assert(test("125-250", 125    , 250));
  assert(test("-125"   , int.min, 125));
  assert(test("125-"   , 125    , int.max));

  // test custom delimiter ".."
  assert(test("125", 125, 125, ".."));
  assert(test("125..250", 125, 250, ".."));
}

/// parse a simple transaction
unittest {
  // test with default config and some mock arguments
  auto cfg = Config.load("nonexistantpath");
  auto args = [ "100", "from", "savings", "to", "credit" ];

  // check command type
  assert(args.operationType(cfg) == OperationType.create);

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
  auto args = [ "98.25", "to", "store", "on", "08/04/15", "for", "stuff" ];

  // check command type
  assert(args.operationType(cfg) == OperationType.create);

  // parse transaction
  auto trans = args.parseTransaction(cfg);
  assert(trans.amount == 98.25f);
  assert(trans.source is null);
  assert(trans.dest == "store");
  assert(trans.date == Date(2015, 8, 4));
  assert(trans.note == "stuff");
}

/// parse a query
unittest {
  // test with default config and some mock arguments
  auto cfg = Config.load("nonexistantpath");
  auto args = [ "list" ]; // just list everythign

  // check command type
  assert(args.operationType(cfg) == OperationType.query);
  assert(args.parseQuery(cfg) == Query.init); // should be default query

  args = [ "list", "amount", "250-525", "from", "*bank*" , "on", "05/01/15-05/22/15"];

  // check command type
  assert(args.operationType(cfg) == OperationType.query);
  auto query = args.parseQuery(cfg);
  assert(query.minAmount  == 250f);
  assert(query.maxAmount  == 525f);
  assert(query.minDate    == Date(2015, 5, 1));
  assert(query.maxDate    == Date(2015, 5, 22));
  assert(query.sourceGlob == "*bank*");
  assert(query.destGlob   == "*");
}
