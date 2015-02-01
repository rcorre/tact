/// read and write transaction info in persistent storage
module storage;

import std.string;
import std.datetime;
import config;

/// matches a month and year to a json file
/// storageDir/year/month.json
private enum pathFormat = "%s/%d/%d.json";

private:
/// the path to the json file containing transactions for this date
string dateToPath(Date date, string storageDir) {
  return pathFormat.format(storageDir, date.year, date.month);
}

unittest {
  auto date       = Date(2015, 5, 1);
  auto storageDir = "~/.tact";
  assert(dateToPath(date, storageDir) == "~/.tact/2015/5.json");
}
