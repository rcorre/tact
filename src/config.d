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
    string[string] _aliases;
  }

  @property {
    string[string] aliases() { return _aliases; }
    string dateFormat()      { return _dateFormat; }
    string rangeDelimiter()  { return _rangeDelimiter; }

    string storageDir() {
      assert(_storageDir !is null, "null storage directory");
      return _storageDir.expandTilde;
    }
  }

  this(IniSection ini) {
    _storageDir     = get!string(ini.general, "storageDir", defaultStorageDir);
    _rangeDelimiter = get!string(ini.general, "rangeDelimiter", defaultRangeDelimiter);
    _dateFormat     = get!string(ini.general, "dateFormat", defaultDateFormat);

    auto aliasSection = "alias" in ini.children;
    if (aliasSection !is null) {
      foreach(key, val ; aliasSection.get!IniSection.children) {
        _aliases[key] = val.get!string;
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

    "[alias]",
    `price       = "amount"`,
    `date        = "on"`,
    `description = "note"`,
    `show        = "list"`
  ].joiner("\n");

  cfgPath.write(cfgText.text);

  auto cfg = Config.load(cfgPath);

  // check general settings
  assert(cfg.storageDir == "~/my_custom_dir/tact".expandTilde);
  assert(cfg.dateFormat == "%Y-%m-%d");
  assert(cfg.rangeDelimiter == ":");

  // custom aliases
  assert(cfg.aliases["price"]       == "amount");
  assert(cfg.aliases["date"]        == "on");
  assert(cfg.aliases["description"] == "note");
  assert(cfg.aliases["show"]        == "list");
}
