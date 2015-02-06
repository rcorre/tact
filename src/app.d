import std.stdio;
import config;
import interpreter;

version (Windows) {
  static assert(0, "don't know where windows home dir is!");
}
else {
  private enum configPath = "~/.tactrc";
}

void main(string[] args) {
  bool foundConfig;
  auto cfg = Config.load(configPath);
  writeln(cfg.storageDir);
  //interpretCommand(args); // strip executable name
}
