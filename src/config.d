module config;

import std.conv, std.path, std.file, std.exception;
import ctini.rtini;
import keywords;

version(Windows) {
  static assert(0, "don't know where windows home dir is");
}
else {
  private enum defaultStorageDir = "~/.tact";
}

private enum {
  defaultRangeDelimiter = "-",
  defaultDateFormat     = "%m/%d/%y"
}

/// keywords used to identify transaction and query parameters
enum defaultArgKeywords = [
  "amount"    : ArgKeyword.amount, /// the quantity of money in a transaction
  "from"      : ArgKeyword.source, /// the source (sender) of a transaction
  "to"        : ArgKeyword.dest,   /// the destination (recipient) of a transaction
  "on"        : ArgKeyword.date,   /// to date on which a transaction occured
  "for"       : ArgKeyword.note,   /// a note about the transaction
];

/// keywords used to identify command type
enum defaultCmdKeywords = [
  "add"       : CommandType.create,   /// create a new transaction
  "list"      : CommandType.query,    /// list transactions
  "_complete" : CommandType.complete, /// get bash completion options
];

struct Config {
  private {
    string _rangeDelimiter = defaultRangeDelimiter; /// token to separate min/max args in query
    string _dateFormat     = defaultDateFormat;     /// format used to parse and format dates
    string _storageDir     = defaultStorageDir;     /// directory where transactions are stored
    ArgKeyword[string]  _argKeywords;               /// map string keyword to argument type
    CommandType[string] _cmdKeywords;               /// map string keyword to command type
  }

  @property {
    string rangeDelimiter()           { return _rangeDelimiter; }
    string dateFormat()               { return _dateFormat; }
    ArgKeyword[string] argKeywords()  { return _argKeywords; }
    CommandType[string] cmdKeywords() { return _cmdKeywords; }

    string storageDir() {
      assert(_storageDir !is null, "null storage directory");
      return _storageDir.expandTilde;
    }
  }

  this(IniSection ini) {
    _storageDir     = get!string(ini.general, "storageDir", defaultStorageDir);
    _rangeDelimiter = get!string(ini.general, "rangeDelimiter", defaultRangeDelimiter);
    _dateFormat     = get!string(ini.general, "dateFormat", defaultDateFormat);

    // replace default keywords from config entries
    _cmdKeywords = defaultCmdKeywords;
    _argKeywords = defaultArgKeywords;
    if ("keywords" in ini.children) {
      foreach(key, val ; ini.keywords.children) {
        string name = val.get!string;
        CommandType cmdType;
        ArgKeyword  argType;
        // first try to set a command keyword
        if ((cmdType = key.parseKeywordType!CommandType) != CommandType.invalid) {
          _cmdKeywords[name] = cmdType;
        }
        else if ((argType = key.parseKeywordType!ArgKeyword) != ArgKeyword.invalid) {
          _argKeywords[name] = argType;
        }
        else {
          enforce(0, "Error parsing config. " ~ key ~ "is not a known tact keyword");
        }
      }
    }
  }

  /// load from ini
  static Config load(string path) {
    Config cfg;
    auto expandedPath = path.expandTilde;

    if (expandedPath.exists) {               // load config
      cfg = Config(iniConfig(expandedPath));
    }
    else {                                   // default config
      cfg._cmdKeywords = defaultCmdKeywords;
      cfg._argKeywords = defaultArgKeywords;
    }

    return cfg;
  }
}

private:
/// get a value from `section` matching `key`, or `defaultVal` if the key is not found
T get(T)(IniSection section, string key, T defaultVal) {
  return (key in section.children) ?  section.get!T(key) : defaultVal;
}

unittest {
  import std.file;
  import std.path;
  import std.conv : text;
  import std.algorithm : joiner;
  // set up temp dir to load from
  auto cfgDir  = buildPath(tempDir(), "tact_unittest");
  auto cfgPath = buildPath(cfgDir, "tactrc");
  assert(!cfgDir.exists, "unittest failure: " ~ cfgDir ~ " already exists");

  cfgDir.mkdirRecurse;
  scope(exit) {
    if (cfgDir.exists) {
      cfgDir.rmdirRecurse;
    }
  }

  // write out a mock config file
  auto cfgText = [
    "[general]",
    `storageDir     = "~/my_custom_dir/tact"`,
    `rangeDelimiter = ":"`,
    `dateFormat     = "%Y-%m-%d"`,

    "[keywords]",
    `amount  = "price"`,
    `date    = "date"`,
    `note    = "description"`
    `query   = "show"`
  ].joiner("\n");

  cfgPath.write(cfgText.text);

  auto cfg = Config.load(cfgPath);

  // check general settings
  assert(cfg.storageDir == "~/my_custom_dir/tact".expandTilde);
  assert(cfg.dateFormat == "%Y-%m-%d");
  assert(cfg.rangeDelimiter == ":");

  // populate expected default keywords
  auto expectedArgKeywords = defaultArgKeywords;
  auto expectedCmdKeywords = defaultCmdKeywords;
  std.stdio.writeln(expectedArgKeywords);
  std.stdio.writeln(cfg.argKeywords);
  // set keywords that are expected to differ
  expectedArgKeywords["price"]       = ArgKeyword.amount;
  expectedArgKeywords["date"]        = ArgKeyword.date;
  expectedArgKeywords["description"] = ArgKeyword.note;
  expectedCmdKeywords["show"]        = CommandType.query;

  assert(cfg.argKeywords == expectedArgKeywords);
  assert(cfg.cmdKeywords == expectedCmdKeywords);
}
