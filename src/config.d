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
enum defaultParameterKeywords = [
  "amount"    : ParameterType.amount, /// the quantity of money in a transaction
  "from"      : ParameterType.source, /// the source (sender) of a transaction
  "to"        : ParameterType.dest,   /// the destination (recipient) of a transaction
  "on"        : ParameterType.date,   /// to date on which a transaction occured
  "for"       : ParameterType.note,   /// a note about the transaction
];

/// keywords used to identify command type
enum defaultOperationKeywords = [
  "add"       : OperationType.create,   /// create a new transaction
  "list"      : OperationType.query,    /// list transactions
  "_complete" : OperationType.complete, /// get bash completion options
];

struct Config {
  private {
    string _rangeDelimiter = defaultRangeDelimiter; /// token to separate min/max args in query
    string _dateFormat     = defaultDateFormat;     /// format used to parse and format dates
    string _storageDir     = defaultStorageDir;     /// directory where transactions are stored
    ParameterType[string] _parameterKeywords;             /// map string keyword to argument type
    OperationType[string] _operationKeywords;             /// map string keyword to command type
  }

  @property {
    string rangeDelimiter()             { return _rangeDelimiter; }
    string dateFormat()                 { return _dateFormat; }

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
    _operationKeywords = defaultOperationKeywords;
    _parameterKeywords = defaultParameterKeywords;
    if ("keywords" in ini.children) {
      foreach(key, val ; ini.keywords.children) {
        string name = val.get!string;
        OperationType cmdType;
        ParameterType  argType;
        // first try to set a command keyword
        if ((cmdType = key.parseKeywordType!OperationType) != OperationType.invalid) {
          _operationKeywords[name] = cmdType;
        }
        else if ((argType = key.parseKeywordType!ParameterType) != ParameterType.invalid) {
          _parameterKeywords[name] = argType;
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
      cfg._operationKeywords = defaultOperationKeywords;
      cfg._parameterKeywords = defaultParameterKeywords;
    }

    return cfg;
  }

  /// translate the given string `keyword` in the corresponding operation
  /// uses the user config to look for custom keywords
  /// returns `OperationType.invalid` if no match is found
  OperationType parseOperationKeyword(string keyword) {
    return keyword.parseKeyword!OperationType(_operationKeywords);
  }

  /// translate the given string `keyword` in the corresponding parameter
  /// uses the user config to look for custom keywords
  /// returns `ParameterType.invalid` if no match is found
  ParameterType parseParameterKeyword(string keyword) {
    return keyword.parseKeyword!ParameterType(_parameterKeywords);
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
    `amount = "price"`,
    `date   = "date"`,
    `note   = "description"`
    `query  = "show"`
  ].joiner("\n");

  cfgPath.write(cfgText.text);

  auto cfg = Config.load(cfgPath);

  // check general settings
  assert(cfg.storageDir == "~/my_custom_dir/tact".expandTilde);
  assert(cfg.dateFormat == "%Y-%m-%d");
  assert(cfg.rangeDelimiter == ":");

  // custom keywords
  assert(cfg.parseParameterKeyword("price")       == ParameterType.amount);
  assert(cfg.parseParameterKeyword("date")        == ParameterType.date);
  //assert(cfg.parseParameterKeyword("description") == ParameterType.note);
  //assert(cfg.parseOperationKeyword("show")        == OperationType.query);

  // default keywords
  assert(cfg.parseParameterKeyword("from") == ParameterType.source);
  assert(cfg.parseOperationKeyword("list") == OperationType.query);
}
