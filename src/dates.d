/// handle conversion between Date and string
module dates;

import std.datetime;
import std.conv : to;
import std.string : toStringz;
import core.sys.posix.time;

private enum strftimeBufSize = 64;

/// convert `date` to a string based on `format`
string dateToString(Date date, string format) {
  const tm = SysTime(date).toTM;
  char[strftimeBufSize] c;
  auto len = strftime(c.ptr, strftimeBufSize, format.toStringz, &tm);
  return c[0 .. len].to!string;
}

/// convert `str` to a Date based on `format`
Date stringToDate(string str, string format) {
  tm time;
  strptime(str.toStringz, format.toStringz, &time);
  // tm_year is years since 1900, tm_mon starts at 0, tm_day starts at 1
  return Date(1900 + time.tm_year, time.tm_mon + 1, time.tm_mday);
}

unittest {
  import std.algorithm : equal;
  enum format = "%m/%d/%y";
  auto date = Date(2015, 5, 1);
  auto str  = "05/01/15";
  assert(date.dateToString(format).equal(str));
  assert(str.stringToDate(format)  == date);
}
