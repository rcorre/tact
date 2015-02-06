module config;

import std.path;
import std.file;
import dini;

version(Windows) {
  static assert(0, "don't know where windows home dir is");
}
else {
  private enum defaultStorageDir = "~/.tact";
}

/// keywords used to identify transaction and query parameters
enum defaultKeywords = [
  "amount"    : "amount", /// the quantity of money in a transaction
  "source"    : "from",   /// the source (sender) of a transaction
  "dest"      : "to",     /// the destination (recipient) of a transaction
  "date"      : "on",     /// to date on which a transaction occured
  "note"      : "note",   /// a note about the transaction
  "endDate"   : "before", /// latest date to include in query
  "startDate" : "after",  /// earliest date to include in query
];

struct Config {
  /// directory where transaction records should be stored
  string storageDir = defaultStorageDir;
  string[string] keywords;

  this(Ini ini) {
    storageDir = ini.getKey("storageDir");

    if (ini.hasSection("keywords")) {
      auto keywordSection = ini.getSection("keywords");
      foreach(key, val ; defaultKeywords) {
        keywords[key] = (key in keywordSection.keys) ?
          keywordSection.getKey(key) :
          defaultKeywords[key];
      }
    }
  }

  /// load from ini
  static Config load(string path) {
    Config cfg;
    auto expandedPath = path.expandTilde;

    if (expandedPath.exists) {
      cfg = Config(Ini.Parse(expandedPath));
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
    "note    = description",
    "invalid = notakeyword",
  ].joiner("\n");

  cfgPath.write(cfgText.text);

  auto cfg = Config.load(cfgPath);
  assert(cfg.storageDir == "~/my_custom_dir/tact");

  auto expectedKeywords = defaultKeywords;
  expectedKeywords["amount"] = "price";
  expectedKeywords["date"]   = "date";
  expectedKeywords["note"]   = "description";

  assert(cfg.keywords == expectedKeywords);
}
