/// provides information for bash completion
module completion;

import std.conv : text;
import std.algorithm : joiner, filter, canFind;
import config;
import command;
import interpreter;

/// provide completion options based on CWORD and COMP_WORDS from bash completion script
string getCompletions(int cword, string[] words, Config cfg) {
  if (words.length == 0 || cword == 1) { // no command given yet
    return "list";
  }

  // command given, get options based on command type
  auto cmdType = words.commandType(cfg);
  assert(cmdType != CommandType.complete, "nested _complete instruction");

  return keywordOptions(words, cmdType);
}

private:
/// return valid keywords that have not yet been used in the current command
/// Params:
///   words = args that have been typed on the cli so far
///   cmdType = the type of the current command as identified by `interpreter.commandType(args)`
string keywordOptions(string[] words, CommandType cmdType) {
  auto allKeywords = (cmdType == CommandType.create) ?
    [ "from", "to", "on", "for" ] :
    [ "from", "to", "on", "for", "amount" ];

  return allKeywords
    .filter!(x => !words.canFind(x)) // don't include keywords that have already been used
    .joiner(" ")                     // join with a space
    .text;                           // return as a single string
}

/// `keywordOptions`
unittest {
  import std.array : split;
  import std.algorithm : all, canFind;
  // test helper. given a string of arguments `argString`,
  // return true if the options provided contain all words in `expected` and nothing more
  bool test(string argString, CommandType cmdType, string expected) {
    string[] words        = argString.split(" ");
    string[] opts         = keywordOptions(words, cmdType).split(" ");
    string[] expectedOpts = expected.split(" ");
    return
      expectedOpts.all!(x => opts.canFind(x)) && // ensure all expected options were returned,
      opts.all!(x => expectedOpts.canFind(x));   // without any unexpected options
  }

  with(CommandType) {
    assert(test("100 ", create, "from to on for"));
    assert(test("list ", query, "from to on for amount"));
    assert(test("100 from credit to debit", create, "for on"));
    assert(test("list amount 100-200.50 on 1/5/2015-2/12/2015", query, "from to for"));
    assert(test("100 to credit fr", create, "from for on"));
  }
}
