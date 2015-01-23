import std.stdio;
import interpreter;

void main(string[] args) {
  try {
    interpretCommand(args); // strip executable name
  }
  catch(Throwable ex) {
    writeln("Error:", ex.msg);
  }
}
