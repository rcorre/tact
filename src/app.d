import std.stdio;
import config;
import storage;
import command;
import interpreter;

version (Windows) {
  static assert(0, "don't know where windows home dir is!");
}
else {
  private enum configPath = "~/.tactrc";
}

void main(string[] args) {
  // load config file, or use default config if not available
  auto cfg = Config.load(configPath);

  // parse input and execute command
  auto input = args[1 .. $]; // strip executable name
  auto cmdType = input.commandType(cfg);

  final switch (cmdType) with (CommandType) {
    case create:
      auto trans = input.parseTransaction(cfg);
      storeTransaction(trans, cfg.storageDir);
      break;
    case query:
      assert(0, "not supported");
  }
}
