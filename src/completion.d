/// provides information for bash completion
module completion;

import std.conv : text;
import std.file : exists;
import std.path : buildPath;
import std.array : array;
import std.algorithm : joiner, filter, canFind;
import config;
import keywords;
import interpreter;
import jsonizer;

private enum cacheFileName = "completion_cache.json";

/// provide completion options based on CWORD and COMP_WORDS from bash completion script
string getCompletions(int cword, string[] words, Config cfg) {
  if (words.length == 0 || cword == 1) { // no command given yet
    return "list";
  }

  // command given, get options based on command type
  auto cmdType = words.operationType(cfg);
  assert(cmdType != OperationType.complete, "nested _complete instruction");

  string[] completions;
  string prevWord = words[cword - 2];
  try {
    auto paramType = parseParameterKeyword(prevWord, cfg.aliases);
    if (paramType == ParameterType.source || paramType == ParameterType.dest) {
      completions = accountNameOptions(cfg.storageDir);
    }
  }
  catch {
    completions = keywordOptions(words, cmdType);
  }
  return completions.joiner(" ").text;
}

/// cache `name` for bash completion in further invocations of the CLI tool
/// does nothing if name is already cached
void cacheAccountName(string name, string storageDir) {
  auto current = accountNameOptions(storageDir);
  if (!current.canFind(name)) {
    current ~= name;
  }
  auto path = buildPath(storageDir, cacheFileName);
  current.writeJSON(path);
}

private:
/// return valid keywords that have not yet been used in the current command
/// Params:
///   words = args that have been typed on the cli so far
///   cmdType = the type of the current command as identified by `interpreter.operationType(args)`
string[] keywordOptions(string[] words, OperationType cmdType) {
  auto allKeywords = (cmdType == OperationType.create) ?
    [ "from", "to", "on", "for" ] :
    [ "from", "to", "on", "for", "amount" ];

  // don't include keywords that have already
  return allKeywords.filter!(x => !words.canFind(x)).array;
}

/// return cached account name options
string[] accountNameOptions(string storageDir) {
  auto path = buildPath(storageDir, cacheFileName);
  return path.exists ? path.readJSON!(string[]) : [];
}

/// `keywordOptions`
unittest {
  import std.array : split;
  import std.algorithm : all, canFind;
  // test helper. given a string of arguments `argString`,
  // return true if the options provided contain all words in `expected` and nothing more
  bool test(string argString, OperationType cmdType, string expected) {
    string[] words        = argString.split(" ");
    string[] opts         = keywordOptions(words, cmdType);
    string[] expectedOpts = expected.split(" ");
    return
      expectedOpts.all!(x => opts.canFind(x)) && // ensure all expected options were returned,
      opts.all!(x => expectedOpts.canFind(x));   // without any unexpected options
  }

  with(OperationType) {
    assert(test("100 ", create, "from to on for"));
    assert(test("list ", query, "from to on for amount"));
    assert(test("100 from credit to debit", create, "for on"));
    assert(test("list amount 100-200.50 on 1/5/2015-2/12/2015", query, "from to for"));
    assert(test("100 to credit fr", create, "from for on"));
  }
}
