package argparse

import "core:fmt"
import "core:log"
import "core:os"
import "core:runtime"
import "core:strings"
import "core:path/filepath"
import "core:unicode/utf8"

import "game:trie"

NargsType :: union {
  int,
  string,
}

_NumTokens :: struct {
  lower: int,
  upper: Maybe(int),
}

_parseNargs :: proc(action: ArgumentAction, vnargs: NargsType) -> (out: _NumTokens, ok: bool) {
  out = _NumTokens{}
  ok = true
  if vnargs != nil {
    switch nargs in vnargs {
    case int:
      if nargs < 0 {
        log.errorf("If nargs is an int, it must be >=0. Got:%v", nargs)
        ok = false
      } else {
        out.lower = nargs
        out.upper = nargs
      }
    case string:
      switch nargs {
      case "?":
        out.lower = 0
        out.upper = 1
      case "*":
        out.lower = 0
        out.upper = {}
      case "+":
        out.lower = 1
        out.upper = {}
      case:
        log.errorf("If nargs is a string, it must be in the set {{\"?\", \"*\", \"+\"}}. Got:\"%v\"", nargs)
        ok = false
      }
    }
  } else {
    // use default 
    switch action {
    case .StoreTrue:
      fallthrough
    case .StoreFalse:
      fallthrough
    case .StoreConst:
      fallthrough
    case .AppendConst:
      fallthrough
    case .Count:
      fallthrough
    case .Help:
      fallthrough
    case .Version:
      out.lower = 0
      out.upper = 0
    ///////////////
    case .Append:
      out.lower = 0
      out.upper = 1
    case .Extend:
      out.lower = 0
      out.upper = {}
    case .Store:
      out.lower = 1
      out.upper = 1
    }
  }
  return
}

_isPositionalOptionNumTokensValid :: proc(action: ArgumentAction, num_tokens: _NumTokens) -> bool {
  switch action {
  case .StoreTrue:
    fallthrough
  case .StoreFalse:
    fallthrough
  case .StoreConst:
    fallthrough
  case .AppendConst:
    fallthrough
  case .Count:
    fallthrough
  case .Help:
    fallthrough
  case .Version:
    fallthrough
  case .Append:
    fallthrough
  case .Extend:
    log.errorf("Argument is positional, but action is %v. This is invalid.", action)
    return false
  case .Store:
  // okay
  }
  return true
}

_isKeywordOptionNumTokensValid :: proc(action: ArgumentAction, num_tokens: _NumTokens) -> bool {
  switch action {
  case .StoreTrue:
    fallthrough
  case .StoreFalse:
    fallthrough
  case .StoreConst:
    fallthrough
  case .AppendConst:
    fallthrough
  case .Count:
    fallthrough
  case .Help:
    fallthrough
  case .Version:
    if num_tokens.lower != 0 || num_tokens.upper != 0 {
      log.errorf("Argument action is %v, so expected num args==0. Got:%v", action, num_tokens)
      return false
    }
  //////////////////
  case .Append:
    fallthrough
  case .Extend:
    fallthrough
  case .Store:
    if upper, upper_ok := num_tokens.upper.?; upper_ok {
      if upper < num_tokens.lower {
        log.errorf("Argument action is %v, so expected upper > lower. Got upper:%v lower:%v", action, upper, num_tokens.lower)
        return false
      }
    }
  }
  return true
}

_isOptionNumTokensValid :: proc(is_positional: bool, action: ArgumentAction, num_tokens: _NumTokens) -> bool {
  if is_positional {
    return _isPositionalOptionNumTokensValid(action, num_tokens)
  }
  return _isKeywordOptionNumTokensValid(action, num_tokens)
}
