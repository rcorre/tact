module config;

import std.path;
import std.file;
import std.exception : enforce;
import dini;

version(Windows) {
  static assert(0, "don't know where windows home dir is");
}
else {
  private enum {
    defaultStorageDir = "~/.tact",
    configPath        = "~/.tactrc"
  }
}

struct Config {
  // members with defaults
  string storageDir = defaultStorageDir;

  // load from ini
  this(Ini ini) {
    storageDir = ini.getKey("storageDir");
  }

  /// returns config loaded from conigPath
  /// returns a default-constructed config if the config file is not found
  static Config load() {
    auto path = configPath.expandTilde;
    Config cfg;
    if (path.exists) {
      cfg = Config(Ini.Parse(path));
    }
    return cfg;
  }
}
