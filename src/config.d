module config;

import std.path, std.file, std.exception;
import dini;
import command;

version(Windows) {
  static assert(0, "don't know where windows home dir is");
}
else {
  private enum defaultStorageDir = "~/.tact";
}

private enum {
  defaultRangeDelimiter = ",",
  defaultDateFormat     = "%m/%d/%y"
}

/// keywords used to identify transaction and query parameters
enum defaultKeywords = [
  "list"   : CommandKeyword.query,  /// the quantity of money in a transaction
  "amount" : CommandKeyword.amount, /// the quantity of money in a transaction
  "from"   : CommandKeyword.source, /// the source (sender) of a transaction
  "to"     : CommandKeyword.dest,   /// the destination (recipient) of a transaction
  "on"     : CommandKeyword.date,   /// to date on which a transaction occured
  "for"    : CommandKeyword.note,   /// a note about the transaction
];

struct Config {
  private {
    string _rangeDelimiter = defaultRangeDelimiter; /// token to separate min/max args in query
    string _dateFormat     = defaultDateFormat;     /// format used to parse and format dates
    string _storageDir     = defaultStorageDir;     /// directory where transactions are stored
    CommandKeyword[string] _keywords;
  }

  @property {
    string rangeDelimiter()           { return _rangeDelimiter; }
    string dateFormat()               { return _dateFormat; }
    CommandKeyword[string] keywords() { return _keywords; }

    string storageDir() {
      assert(_storageDir !is null, "null storage directory");
      return _storageDir.expandTilde;
    }
  }

  this(Ini ini) {
    _storageDir     = ini.keys.get("storageDir", defaultStorageDir);
    _rangeDelimiter = ini.keys.get("rangeDelimiter", defaultRangeDelimiter);
    _dateFormat     = ini.keys.get("dateFormat", defaultDateFormat);

    // replace default keywords from config entries
    _keywords = defaultKeywords;
    if (ini.hasSection("keywords")) {
      auto keywordSection = ini.getSection("keywords");
      foreach(key, val ; keywordSection.keys) {
        try {
          auto keyword = key.to!CommandKeyword;
          _keywords[val] = keyword;
        }
        catch {
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
      cfg = Config(Ini.Parse(expandedPath));
    }
    else {                                   // default config
      cfg._storageDir = defaultStorageDir;
      cfg._keywords   = defaultKeywords;
    }

    return cfg;
  }
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
    "storageDir     = ~/my_custom_dir/tact",
    "rangeDelimiter = :",
    `dateFormat     = "%Y-%m-%d"`,

    "[keywords]",
    "amount  = price",
    "date    = date",
    "note    = description"
  ].joiner("\n");

  cfgPath.write(cfgText.text);

  auto cfg = Config.load(cfgPath);

  assert(cfg.storageDir == "~/my_custom_dir/tact".expandTilde);
  assert(cfg.dateFormat == "%Y-%m-%d");
  assert(cfg.rangeDelimiter == ":");

  auto expectedKeywords           = defaultKeywords;
  expectedKeywords["price"]       = CommandKeyword.amount;
  expectedKeywords["date"]        = CommandKeyword.date;
  expectedKeywords["description"] = CommandKeyword.note;

  assert(cfg.keywords == expectedKeywords);
}
