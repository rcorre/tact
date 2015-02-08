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

/// keywords used to identify transaction and query parameters
enum defaultKeywords = [
  "amount" : CommandKeyword.amount, /// the quantity of money in a transaction
  "from"   : CommandKeyword.source, /// the source (sender) of a transaction
  "to"     : CommandKeyword.dest,   /// the destination (recipient) of a transaction
  "on"     : CommandKeyword.date,   /// to date on which a transaction occured
  "for"    : CommandKeyword.note,   /// a note about the transaction
];

struct Config {
  /// directory where transaction records should be stored
  private string _storageDir;
  @property string storageDir() {
    assert(_storageDir !is null, "null storage directory");
    return _storageDir.expandTilde;
  }
  CommandKeyword[string] keywords;

  this(Ini ini) {
    _storageDir = ini.keys.get("storageDir", defaultStorageDir);

    // replace default keywords from config entries
    keywords = defaultKeywords;
    if (ini.hasSection("keywords")) {
      auto keywordSection = ini.getSection("keywords");
      foreach(key, val ; keywordSection.keys) {
        try {
          auto keyword = key.to!CommandKeyword;
          keywords[val] = keyword;
        }
        catch {
          enforce(0, key ~ " is not a known tact keyword");
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
      cfg.keywords    = defaultKeywords;
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
    "storageDir = ~/my_custom_dir/tact",

    "[keywords]",
    "amount  = price",
    "date    = date",
    "note    = description"
  ].joiner("\n");

  cfgPath.write(cfgText.text);

  auto cfg = Config.load(cfgPath);
  assert(cfg.storageDir == "~/my_custom_dir/tact".expandTilde);

  auto expectedKeywords           = defaultKeywords;
  expectedKeywords["price"]       = CommandKeyword.amount;
  expectedKeywords["date"]        = CommandKeyword.date;
  expectedKeywords["description"] = CommandKeyword.note;

  assert(cfg.keywords == expectedKeywords);
}
