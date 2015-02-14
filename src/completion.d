/// provides information for bash completion
module completion;

import config;
import command;
import interpreter;

/// provide completion options based on CWORD and COMP_WORDS from bash completion script
string getCompletions(int cword, string[] words, Config cfg) {
  if (words.length == 0) { // no command given yet
    return "list";
  }

  // command given, strip command keyword and provide completions based on command
  final switch (words.commandType(cfg)) with (CommandType) {
    case create:
      return createCommandCompletions(words[1 .. $]);
    case query:
      return queryCommandCompletions(words[1 .. $]);
    case complete:
  }
  assert(0, "nested _complete instruction");
}

private:
string createCommandCompletions(string[] words) {
  return "from to on for";
}

string queryCommandCompletions(string[] words) {
  return "from to on for";
}
