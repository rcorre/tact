import std.stdio;
import config;
import interpreter;

void main(string[] args) {
  bool foundConfig;
  auto cfg = Config.load;
  writeln(cfg.storageDir);
  //interpretCommand(args); // strip executable name
}
