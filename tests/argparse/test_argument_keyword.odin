// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_argparse

import "core:fmt"
import "core:log"
import "core:runtime"
import "core:strings"
import "core:testing"
import "game:argparse"
import "game:trie"
import tc "tests:common"


@(test)
test_ArgParse_Keyword :: proc(t: ^testing.T) {
  test_makeOptionProcessingState(t)
  test_determineKeywordOption(t)
  test_processKeywordOption(t)
}

//////////////////////////////////////////////////////////////////

@(test)
test_makeOptionProcessingState :: proc(t: ^testing.T) {
  using argparse
  using strings
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  num_tokens := []_NumTokens{_NumTokens{}, _NumTokens{0, nil}, _NumTokens{1, nil}}
  for alloc in allocs {
    for nt in num_tokens {
      for action in ArgumentAction {
        state := _makeOptionProcessingState(action, nt, alloc)
        switch data in &state.data {
        case bool:
        case int:
        case string:
          data = clone("asdf", alloc)
        case [dynamic]string:
          append(&data, clone("string data", alloc))
          append(&data, clone("string data", alloc))
          append(&data, clone("string data", alloc))
        case [dynamic][dynamic]string:
          vals := make([dynamic]string, 1, alloc)
          vals[0] = clone("data00", alloc)
          append(&data, vals)
          vals = make([dynamic]string, 1, alloc)
          vals[0] = clone("data11", alloc)
          append(&data, vals)
        }
        _deleteOptionProcessingState(&state)
        tc.expect(t, state.data == nil)
      }
    }
  }
}

//////////////////////////////////////////////////////////////////
@(private = "file")
MakeArgumentParserArgs :: struct {
  add_help: bool,
}

@(private = "file")
AddArgumentArgs :: struct {
  action: argparse.ArgumentAction,
  flags:  []string,
}

@(private = "file")
DetermineKeywordOptionTest :: struct {
  input:    string,
  expected: argparse._FoundKeywordOption(string),
}

@(private = "file")
DetermineKeywordOptionFixture :: struct {
  argparser_args: MakeArgumentParserArgs,
  make_arg_args:  []AddArgumentArgs,
  tests:          []DetermineKeywordOptionTest,
}

@(test)
test_determineKeywordOption :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  fixtures := []DetermineKeywordOptionFixture{
    {
      make_arg_args = []AddArgumentArgs{{action = .Store, flags = []string{"-a"}}},
      tests = []DetermineKeywordOptionTest{
        {input = "-a", expected = _FoundKeywordOption(string){flag_type = .Short, value = "a", trailer = nil, removed_equal_prefix = false}},
        {input = "", expected = _FoundKeywordOption(string){flag_type = .Invalid, value = "", trailer = nil, removed_equal_prefix = false}},
        {input = "-", expected = _FoundKeywordOption(string){flag_type = .Invalid, value = "", trailer = nil, removed_equal_prefix = false}},
        {input = "--", expected = _FoundKeywordOption(string){flag_type = .Invalid, value = "", trailer = nil, removed_equal_prefix = false}},
        {input = "-b", expected = _FoundKeywordOption(string){flag_type = .Short, value = "", trailer = nil, removed_equal_prefix = false, is_unknown = true}},
        {input = "-aa", expected = _FoundKeywordOption(string){flag_type = .Short, value = "a", trailer = "a", removed_equal_prefix = false}},
        {input = "-a=a", expected = _FoundKeywordOption(string){flag_type = .Short, value = "a", trailer = "a", removed_equal_prefix = true}},
      },
    },
    {
      make_arg_args = []AddArgumentArgs{{action = .Store, flags = []string{"--a"}}},
      tests = []DetermineKeywordOptionTest{
        {input = "--a", expected = _FoundKeywordOption(string){flag_type = .Long, value = "a", trailer = nil, removed_equal_prefix = false}},
        {input = "", expected = _FoundKeywordOption(string){flag_type = .Invalid, value = "", trailer = nil, removed_equal_prefix = false}},
        {input = "-", expected = _FoundKeywordOption(string){flag_type = .Invalid, value = "", trailer = nil, removed_equal_prefix = false}},
        {input = "--", expected = _FoundKeywordOption(string){flag_type = .Invalid, value = "", trailer = nil, removed_equal_prefix = false}},
        {input = "-b", expected = _FoundKeywordOption(string){flag_type = .Short, value = "", trailer = nil, removed_equal_prefix = false, is_unknown = true}},
        {input = "--a=3", expected = _FoundKeywordOption(string){flag_type = .Long, value = "a", trailer = "3", removed_equal_prefix = true}},
      },
    },
    {
      make_arg_args = []AddArgumentArgs{{action = .Store, flags = []string{"-aaa"}}},
      tests = []DetermineKeywordOptionTest{
        {input = "-a", expected = _FoundKeywordOption(string){flag_type = .Short, value = "aaa", trailer = nil, removed_equal_prefix = false}},
        {input = "-aa", expected = _FoundKeywordOption(string){flag_type = .Short, value = "aaa", trailer = nil, removed_equal_prefix = false}},
        {input = "-aaa", expected = _FoundKeywordOption(string){flag_type = .Short, value = "aaa", trailer = nil, removed_equal_prefix = false}},
        {input = "-aaaa", expected = _FoundKeywordOption(string){flag_type = .Short, value = "aaa", trailer = "a", removed_equal_prefix = false}},
        {input = "", expected = _FoundKeywordOption(string){flag_type = .Invalid, value = "", trailer = nil, removed_equal_prefix = false}},
        {input = "-", expected = _FoundKeywordOption(string){flag_type = .Invalid, value = "", trailer = nil, removed_equal_prefix = false}},
        {input = "--", expected = _FoundKeywordOption(string){flag_type = .Invalid, value = "", trailer = nil, removed_equal_prefix = false}},
        {input = "-b", expected = _FoundKeywordOption(string){flag_type = .Short, value = "", trailer = nil, removed_equal_prefix = false, is_unknown = true}},
      },
    },
    {
      make_arg_args = []AddArgumentArgs{{action = .Store, flags = []string{"-a"}}, {action = .Store, flags = []string{"-ab"}}},
      tests = []DetermineKeywordOptionTest{
        {input = "-a", expected = _FoundKeywordOption(string){flag_type = .Short, value = "a", trailer = nil, removed_equal_prefix = false}},
        {input = "-ab", expected = _FoundKeywordOption(string){flag_type = .Short, value = "ab", trailer = nil, removed_equal_prefix = false}},
        {input = "-a=3", expected = _FoundKeywordOption(string){flag_type = .Short, value = "a", trailer = "3", removed_equal_prefix = true}},
        {input = "-ab=3", expected = _FoundKeywordOption(string){flag_type = .Short, value = "ab", trailer = "3", removed_equal_prefix = true}},
      },
    },
    {
      make_arg_args = []AddArgumentArgs{{action = .Store, flags = []string{"--a"}}, {action = .Store, flags = []string{"--ab"}}},
      tests = []DetermineKeywordOptionTest{
        {input = "--a", expected = _FoundKeywordOption(string){flag_type = .Long, value = "a", trailer = nil, removed_equal_prefix = false}},
        {input = "--ab", expected = _FoundKeywordOption(string){flag_type = .Long, value = "ab", trailer = nil, removed_equal_prefix = false}},
        {input = "--a=3", expected = _FoundKeywordOption(string){flag_type = .Long, value = "a", trailer = "3", removed_equal_prefix = true}},
        {input = "--ab=3", expected = _FoundKeywordOption(string){flag_type = .Long, value = "ab", trailer = "3", removed_equal_prefix = true}},
      },
    },
    {
      make_arg_args = []AddArgumentArgs{{action = .Store, flags = []string{"--long1", "--long2", "--long3"}}},
      tests = []DetermineKeywordOptionTest{
        {input = "--lon", expected = _FoundKeywordOption(string){flag_type = .Long, value = "long1", trailer = nil, removed_equal_prefix = false}},
        {input = "--lon=3", expected = _FoundKeywordOption(string){flag_type = .Long, value = "long1", trailer = "3", removed_equal_prefix = true}},
        {input = "--long1=3", expected = _FoundKeywordOption(string){flag_type = .Long, value = "long1", trailer = "3", removed_equal_prefix = true}},
        {input = "--long13", expected = _FoundKeywordOption(string){flag_type = .Long, value = "long1", trailer = "3", removed_equal_prefix = false}},
      },
    },
    {
      make_arg_args = []AddArgumentArgs{{action = .Store, flags = []string{"--long1"}}, {action = .Store, flags = []string{"--long2"}}},
      tests = []DetermineKeywordOptionTest{
        {input = "--lon", expected = _FoundKeywordOption(string){flag_type = .Long, value = "", trailer = nil, removed_equal_prefix = false, is_error = true}},
        {
          input = "--lon=3",
          expected = _FoundKeywordOption(string){flag_type = .Long, value = "", trailer = nil, removed_equal_prefix = false, is_error = true},
        },
        {input = "--long1=3", expected = _FoundKeywordOption(string){flag_type = .Long, value = "long1", trailer = "3", removed_equal_prefix = true}},
        {input = "--long13", expected = _FoundKeywordOption(string){flag_type = .Long, value = "long1", trailer = "3", removed_equal_prefix = false}},
      },
    },
    {
      make_arg_args = []AddArgumentArgs{{action = .Count, flags = []string{"-v", "--verbose"}}, {action = .Count, flags = []string{"-c", "--count"}}},
      tests = []DetermineKeywordOptionTest{
        {input = "--verb", expected = _FoundKeywordOption(string){flag_type = .Long, value = "verbose", trailer = nil, removed_equal_prefix = false}},
        {input = "-v", expected = _FoundKeywordOption(string){flag_type = .Short, value = "verbose", trailer = nil, removed_equal_prefix = false}},
        {input = "-a", expected = _FoundKeywordOption(string){flag_type = .Short, value = "", trailer = nil, removed_equal_prefix = false, is_unknown = true}},
      },
    },
  }

  for alloc in allocs {
    fixture_loop: for fixture, fixture_idx in &fixtures {
      ap, ap_ok := makeArgumentParser(add_help = fixture.argparser_args.add_help, allocator = alloc)
      defer deleteArgumentParser(&ap)
      for arg_args in fixture.make_arg_args {
        opt, opt_ok := addArgument(self = &ap, flags = arg_args.flags, action = arg_args.action)
        tc.expect(t, opt_ok)
        if !opt_ok {
          continue fixture_loop
        }
      }
      for test, test_idx in &fixture.tests {
        out := _determineKeywordOption(kw_trie = &ap._kw_trie, arg = test.input, prefix_rune = ap._prefix_rune, equality_rune = ap._equality_rune)
        tc.expect(
          t,
          test.expected.value == out.value,
          fmt.tprintf("Test[%v][%v]: value: Expected:%q; Got:%q", fixture_idx, test_idx, test.expected.value, out.value),
        )
        tc.expect(
          t,
          (test.expected.trailer == out.trailer) || ((test.expected.trailer == nil) && (out.trailer == nil)),
          fmt.tprintf("Test[%v][%v]: trailer: Expected:%q; Got:%q", fixture_idx, test_idx, test.expected.trailer, out.trailer),
        )
        tc.expect(
          t,
          (test.expected.is_unknown == out.is_unknown),
          fmt.tprintf("Test[%v][%v]: is_unknown: Expected:%v; Got:%v", fixture_idx, test_idx, test.expected.is_unknown, out.is_unknown),
        )
        tc.expect(
          t,
          (test.expected.is_error == out.is_error),
          fmt.tprintf("Test[%v][%v]: is_error: Expected:%q; Got:%q", fixture_idx, test_idx, test.expected.is_error, out.is_error),
        )
        tc.expect(
          t,
          test.expected.removed_equal_prefix == out.removed_equal_prefix,
          fmt.tprintf(
            "Test[%v][%v]: removed_equal_prefix: Expected:%v; Got:%v",
            fixture_idx,
            test_idx,
            test.expected.removed_equal_prefix,
            out.removed_equal_prefix,
          ),
        )
        tc.expect(
          t,
          _isequal_FoundKeywordOption(&test.expected, &out),
          fmt.tprintf("Test[%v][%v] input:%q:\nExpected:%v\nGot     :%v", fixture_idx, test_idx, test.input, test.expected, out),
        )
      }
    }
  }
}

//////////////////////////////////////////////////////////////////

@(test)
test_processKeywordOption :: proc(t: ^testing.T) {
  using argparse
  for action in ArgumentAction {
    switch action {
    case .Store:
      test_processKeywordOption_Store(t)
    case .StoreTrue:
      test_processKeywordOption_StoreTrue(t)
    case .StoreFalse:
      test_processKeywordOption_StoreFalse(t)
    case .Help:
      test_processKeywordOption_Help(t)
    case .Version:
      test_processKeywordOption_Version(t)
    case .Extend:
      test_processKeywordOption_Extend(t)
    case .Count:
      test_processKeywordOption_Count(t)
    case .Append:
      test_processKeywordOption_Append(t)
    }
  }
}

@(test)
test_processKeywordOption_Store :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      // scalar
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, action = .Store)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_str, data_str_ok := &proc_state.data.(string)
      tc.expect(t, data_str_ok)
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, !ok, "Expected not okay")
      }
      {
        input_trailer := "foo"
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, data_str^ == input_trailer)
      }
      {
        input_arg0 := "bar"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 1)
        tc.expect(t, data_str^ == input_arg0)
      }
    }
    {
      // lower=2
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = 2, action = .Store)
      tc.expect(t, option != nil)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_strs, data_ok := &proc_state.data.([dynamic]string)
      tc.expect(t, data_ok)
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, !ok, "Expected not okay")
      }
      {
        input_trailer := "foo"
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {})
        tc.expect(t, !ok, "Expected not okay")
      }
      {
        input_arg0 := "bar0"
        input_arg1 := "bar1"
        input_arg2 := "2222"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, input_arg1, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 2)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_arg0, input_arg1}))
        // second confirms overwrite of state
        proc_out, ok = _processKeywordOption(option, &proc_state, nil, {input_arg2, input_arg2, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 2)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_arg2, input_arg2}))
      }
    }
    {
      // ?
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "?", action = .Store)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_strs, data_ok := &proc_state.data.([dynamic]string)
      tc.expect(t, data_ok)
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, isequal_slice(data_strs^[:], []string{}))
      }
      {
        input_trailer := "foo"
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_trailer}))
      }
      {
        input_arg0 := "bar0"
        input_arg1 := "bar1"
        input_arg2 := "2222"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, input_arg1, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 1)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_arg0}))
        // second confirms overwrite of state
        proc_out, ok = _processKeywordOption(option, &proc_state, nil, {input_arg2, input_arg2, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 1)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_arg2}))
      }
    }
    {
      // *
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "*", action = .Store)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_strs, data_ok := &proc_state.data.([dynamic]string)
      tc.expect(t, data_ok)
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, isequal_slice(data_strs^[:], []string{}))
      }
      {
        input_trailer := "foo"
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {input_trailer, input_trailer})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_trailer}))
      }
      {
        input_arg0 := "bar0"
        input_arg1 := "bar1"
        input_arg2 := "2222"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, input_arg1, input_arg2})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 3)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_arg0, input_arg1, input_arg2}))
        // second confirms overwrite of state
        proc_out, ok = _processKeywordOption(option, &proc_state, nil, {input_arg2, input_arg2})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 2)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_arg2, input_arg2}))
      }
    }
    {
      // +
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "+", action = .Store)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_strs, data_ok := &proc_state.data.([dynamic]string)
      tc.expect(t, data_ok)
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, !ok, "Expected not okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
      }
      {
        input_trailer := "foo"
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {input_trailer, input_trailer})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_trailer}))
      }
      {
        input_arg0 := "bar0"
        input_arg1 := "bar1"
        input_arg2 := "2222"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, input_arg1, input_arg2})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 3)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_arg0, input_arg1, input_arg2}))
        // second confirms overwrite of state
        proc_out, ok = _processKeywordOption(option, &proc_state, nil, {input_arg2, input_arg2})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 2)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_arg2, input_arg2}))
      }
    }
  }
}

@(test)
test_processKeywordOption_StoreTrue :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      // scalar
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, action = .StoreTrue)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_bool, data_bool_ok := &proc_state.data.(bool)
      tc.expect(t, data_bool_ok)
      tc.expect(t, data_bool^ == false)
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, data_bool^ == true)
        data_bool^ = false
      }
      {
        input_trailer := "foo"
        proc_out, ok := _processKeywordOption(option = option, state = &proc_state, trailer = input_trailer, args = {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer != nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, data_bool^ == true)
        data_bool^ = false
      }
      {
        input_arg0 := "bar"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, data_bool^ == true)
        data_bool^ = false
      }
    }
    {
      // lower=2
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = 2, action = .StoreTrue)
      tc.expect(t, !opt_ok)
    }
    {
      // ?
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "?", action = .StoreTrue)
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
    {
      // *
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "*", action = .StoreTrue)
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
    {
      // +
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "+", action = .StoreTrue)
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
  }
}

@(test)
test_processKeywordOption_StoreFalse :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      // scalar
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, action = .StoreFalse)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_bool, data_bool_ok := &proc_state.data.(bool)
      tc.expect(t, data_bool_ok)
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, data_bool^ == false)
        data_bool^ = true
      }
      {
        input_trailer := "foo"
        proc_out, ok := _processKeywordOption(option = option, state = &proc_state, trailer = input_trailer, args = {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer != nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, data_bool^ == false)
        data_bool^ = true
      }
      {
        input_arg0 := "bar"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, data_bool^ == false)
        data_bool^ = true
      }
    }
    {
      // lower=2
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = 2, action = .StoreFalse)
      tc.expect(t, !opt_ok)
    }
    {
      // ?
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "?", action = .StoreFalse)
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
    {
      // *
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "*", action = .StoreFalse)
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
    {
      // +
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "+", action = .StoreFalse)
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
  }
}

@(test)
test_processKeywordOption_Help :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      // scalar
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"-h", "--help"}, action = .Help)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      tc.expect(t, proc_state.data == nil)
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, ok, "Expected okay")
      }
      {
        input_trailer := "foo"
        proc_out, ok := _processKeywordOption(option = option, state = &proc_state, trailer = input_trailer, args = {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer != nil)
        tc.expect(t, proc_out.num_consumed == 0)
      }
      {
        input_arg0 := "bar"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
      }
    }
    {
      // lower=2
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"-h", "--help"}, action = .Help, nargs = 2)
      tc.expect(t, !opt_ok)
    }
    {
      // ?
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"-h", "--help"}, action = .Help, nargs = "?")
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
    {
      // *
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"-h", "--help"}, action = .Help, nargs = "*")
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
    {
      // +
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"-h", "--help"}, action = .Help, nargs = "+")
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
  }
}


@(test)
test_processKeywordOption_Version :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      // scalar
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"-h", "--help"}, action = .Version)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      tc.expect(t, proc_state.data == nil)
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, ok, "Expected okay")
      }
      {
        input_trailer := "foo"
        proc_out, ok := _processKeywordOption(option = option, state = &proc_state, trailer = input_trailer, args = {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer != nil)
        tc.expect(t, proc_out.num_consumed == 0)
      }
      {
        input_arg0 := "bar"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
      }
    }
    {
      // lower=2
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"-h", "--help"}, action = .Version, nargs = 2)
      tc.expect(t, !opt_ok)
    }
    {
      // ?
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"-h", "--help"}, action = .Version, nargs = "?")
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
    {
      // *
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"-h", "--help"}, action = .Version, nargs = "*")
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
    {
      // +
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"-h", "--help"}, action = .Version, nargs = "+")
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
  }
}

@(test)
test_processKeywordOption_Extend :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      // scalar
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, action = .Extend)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      {
        expected := _NumTokens{1, 1}
        tc.expect(t, option.num_tokens == expected, fmt.tprintf("\nExpected:%v\n     Got:%v", expected, option.num_tokens))
      }
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_strs, data_strs_ok := &proc_state.data.([dynamic]string)
      tc.expect(t, data_strs_ok)
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, !ok, "Expected not okay")
      }
      input_trailer := "foo"
      input_arg0 := "bar"
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {input_trailer, input_trailer})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_trailer}))
      }
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, input_arg0, input_arg0})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 1, fmt.tprintf("Expected:1 Got:%v", proc_out.num_consumed))
        expected := []string{input_trailer, input_arg0}
        tc.expect(t, isequal_slice(data_strs^[:], expected), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, data_strs^))
      }
    }
    {
      // lower=2
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = 2, action = .Extend)
      tc.expect(t, option != nil)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_strs, data_ok := &proc_state.data.([dynamic]string)
      tc.expect(t, data_ok)
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, !ok, "Expected not okay")
      }
      {
        input_trailer := "foo"
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {})
        tc.expect(t, !ok, "Expected not okay")
      }
      {
        input_arg0 := "bar0"
        input_arg1 := "bar1"
        input_arg2 := "2222"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, input_arg1, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 2)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_arg0, input_arg1}))
        // second confirms extension of state
        proc_out, ok = _processKeywordOption(option, &proc_state, nil, {input_arg2, input_arg2, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 2)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_arg0, input_arg1, input_arg2, input_arg2}))
      }
    }
    {
      // ?
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "?", action = .Extend)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_strs, data_ok := &proc_state.data.([dynamic]string)
      tc.expect(t, data_ok)
      input_trailer := "foo"
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, isequal_slice(data_strs^[:], []string{}))
      }
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_trailer}))
      }
      {
        input_arg0 := "bar0"
        input_arg1 := "bar1"
        input_arg2 := "2222"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, input_arg1, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 1)
        expected1 := []string{input_trailer, input_arg0}
        tc.expect(t, isequal_slice(data_strs^[:], expected1), fmt.tprintf("\nExpected:%v     \nGot:%v", expected1, data_strs))
        // second confirms extension of state
        proc_out, ok = _processKeywordOption(option, &proc_state, nil, {input_arg2, input_arg2, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 1)
        expected2 := []string{input_trailer, input_arg0, input_arg2}
        tc.expect(t, isequal_slice(data_strs^[:], expected2), fmt.tprintf("\nExpected:%v\n     Got:%v", expected2, data_strs^))
      }
    }
    {
      // *
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "*", action = .Extend)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_strs, data_ok := &proc_state.data.([dynamic]string)
      tc.expect(t, data_ok)
      input_trailer := "foo"
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, isequal_slice(data_strs^[:], []string{}))
      }
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {input_trailer, input_trailer})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_trailer}))
      }
      {
        input_arg0 := "bar0"
        input_arg1 := "bar1"
        input_arg2 := "2222"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, input_arg1, input_arg2})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 3)
        expected1 := []string{input_trailer, input_arg0, input_arg1, input_arg2}
        tc.expect(t, isequal_slice(data_strs^[:], expected1), fmt.tprintf("\nExpected:%v\n     Got:%v", expected1, data_strs^))
        // second confirms extension of state
        proc_out, ok = _processKeywordOption(option, &proc_state, nil, {input_arg2, input_arg2})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 2)
        expected2 := []string{input_trailer, input_arg0, input_arg1, input_arg2, input_arg2, input_arg2}
        tc.expect(t, isequal_slice(data_strs^[:], expected2), fmt.tprintf("\nExpected:%v\n     Got:%v", expected2, data_strs^))
      }
    }
    {
      // +
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "+", action = .Extend)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_strs, data_ok := &proc_state.data.([dynamic]string)
      tc.expect(t, data_ok)
      input_trailer := "foo"
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, !ok, "Expected not okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
      }
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {input_trailer, input_trailer})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_trailer}))
      }
      {
        input_arg0 := "bar0"
        input_arg1 := "bar1"
        input_arg2 := "2222"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, input_arg1, input_arg2})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 3)
        expected1 := []string{input_trailer, input_arg0, input_arg1, input_arg2}
        tc.expect(t, isequal_slice(data_strs^[:], expected1), fmt.tprintf("\nExpected:%v\n     Got:%v", expected1, data_strs^))
        // second confirms extension of state
        proc_out, ok = _processKeywordOption(option, &proc_state, nil, {input_arg2, input_arg2})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 2)
        expected2 := []string{input_trailer, input_arg0, input_arg1, input_arg2, input_arg2, input_arg2}
        tc.expect(t, isequal_slice(data_strs^[:], expected2), fmt.tprintf("\nExpected:%v\n     Got:%v", expected2, data_strs^))
      }
    }
  }
}

@(test)
test_processKeywordOption_Count :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      // scalar
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, action = .Count)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_int, data_int_ok := &proc_state.data.(int)
      tc.expect(t, data_int_ok)
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, data_int^ == 1)
      }
      {
        input_trailer := "foo"
        proc_out, ok := _processKeywordOption(option = option, state = &proc_state, trailer = input_trailer, args = {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer != nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, data_int^ == 2)
      }
      {
        input_arg0 := "bar"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, data_int^ == 3)
        proc_out, ok = _processKeywordOption(option, &proc_state, nil, {input_arg0, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, data_int^ == 4)
      }
    }
    {
      // lower=2
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = 2, action = .Count)
      tc.expect(t, !opt_ok)
    }
    {
      // ?
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "?", action = .Count)
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
    {
      // *
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "*", action = .Count)
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
    {
      // +
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "+", action = .Count)
      tc.expect(t, option == nil)
      tc.expect(t, !opt_ok)
    }
  }
}

@(test)
test_processKeywordOption_Append :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      // scalar
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, action = .Append)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      {
        expected := _NumTokens{1, 1}
        tc.expect(t, option.num_tokens == expected, fmt.tprintf("\nExpected:%v\n     Got:%v", expected, option.num_tokens))
      }
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_strs, data_strs_ok := &proc_state.data.([dynamic]string)
      tc.expect(t, data_strs_ok)
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, !ok, "Expected not okay")
      }
      input_trailer := "foo"
      input_arg0 := "bar"
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {input_trailer, input_trailer})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        tc.expect(t, isequal_slice(data_strs^[:], []string{input_trailer}))
      }
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, input_arg0, input_arg0})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 1, fmt.tprintf("Expected:1 Got:%v", proc_out.num_consumed))
        expected := []string{input_trailer, input_arg0}
        tc.expect(t, isequal_slice(data_strs^[:], expected), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, data_strs^))
      }
    }
    {
      // lower=2
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = 2, action = .Append)
      tc.expect(t, option != nil)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_astrs, data_ok := &proc_state.data.([dynamic][dynamic]string)
      tc.expect(t, data_ok)
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, !ok, "Expected not okay")
      }
      {
        input_trailer := "foo"
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {})
        tc.expect(t, !ok, "Expected not okay")
      }
      {
        input_arg0 := "bar0"
        input_arg1 := "bar1"
        input_arg2 := "2222"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, input_arg1, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 2)
        expected1 := [][dynamic]string{{input_arg0, input_arg1}}
        tc.expect(t, isequal_slice2(data_astrs^[:], expected1[:]), fmt.tprintf("\nExpected:%v\n    Out:%v", expected1, data_astrs^))
        // second confirms overwrite of state
        proc_out, ok = _processKeywordOption(option, &proc_state, nil, {input_arg2, input_arg2, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        expected2 := [][dynamic]string{{input_arg0, input_arg1}, {input_arg2, input_arg2}}
        tc.expect(t, proc_out.num_consumed == 2)
        tc.expect(t, isequal_slice2(data_astrs^[:], expected2[:]), fmt.tprintf("\nExpected:%v\n    Out:%v", expected2, data_astrs^))
      }
    }
    {
      // ?
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "?", action = .Append)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_astrs, data_ok := &proc_state.data.([dynamic][dynamic]string)
      tc.expect(t, data_ok, fmt.tprintf("Expected ok. Got proc_state:%v", proc_state))
      input_trailer := "foo"
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        expected := [][dynamic]string{{}}
        tc.expect(t, isequal_slice2(data_astrs^[:], expected[:]), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, data_astrs^))
      }
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        expected := [][dynamic]string{{}, {input_trailer}}
        tc.expect(t, isequal_slice2(data_astrs^[:], expected[:]), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, data_astrs^))
      }
      {
        input_arg0 := "bar0"
        input_arg1 := "bar1"
        input_arg2 := "2222"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, input_arg1, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 1)
        expected1 := [][dynamic]string{{}, {input_trailer}, {input_arg0}}
        tc.expect(t, isequal_slice2(data_astrs^[:], expected1[:]), fmt.tprintf("\nExpected:%v\n     Got:%v", expected1, data_astrs^))
        // second confirms append of state
        proc_out, ok = _processKeywordOption(option, &proc_state, nil, {input_arg2, input_arg2, "extra", "extra33"})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 1)
        expected2 := [][dynamic]string{{}, {input_trailer}, {input_arg0}, {input_arg2}}
        tc.expect(t, isequal_slice2(data_astrs^[:], expected2[:]), fmt.tprintf("\nExpected:%v\n     Got:%v", expected2, data_astrs^))
      }
    }
    {
      // *
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "*", action = .Append)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_astrs, data_ok := &proc_state.data.([dynamic][dynamic]string)
      tc.expect(t, data_ok)
      input_trailer := "foo"
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        expected := [][dynamic]string{{}}
        tc.expect(t, isequal_slice2(data_astrs^[:], expected[:]), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, data_astrs^))
      }
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {input_trailer, input_trailer})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        expected := [][dynamic]string{{}, {input_trailer}}
        tc.expect(t, isequal_slice2(data_astrs^[:], expected[:]), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, data_astrs^))
      }
      {
        input_arg0 := "bar0"
        input_arg1 := "bar1"
        input_arg2 := "2222"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, input_arg1, input_arg2})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 3)
        expected1 := [][dynamic]string{{}, {input_trailer}, {input_arg0, input_arg1, input_arg2}}
        tc.expect(t, isequal_slice2(data_astrs^[:], expected1[:]), fmt.tprintf("\nExpected:%v\n     Got:%v", expected1, data_astrs^))
        // second confirms append of state
        proc_out, ok = _processKeywordOption(option, &proc_state, nil, {input_arg2, input_arg2})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 2)
        expected2 := [][dynamic]string{{}, {input_trailer}, {input_arg0, input_arg1, input_arg2}, {input_arg2, input_arg2}}
        tc.expect(t, isequal_slice2(data_astrs^[:], expected2[:]), fmt.tprintf("\nExpected:%v\n     Got:%v", expected2, data_astrs^))
      }
    }
    {
      // +
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      option, opt_ok := addArgument(self = &ap, flags = {"--a"}, nargs = "+", action = .Append)
      tc.expect(t, option != nil)
      tc.expect(t, opt_ok)
      proc_state, proc_state_ok := _makeOptionProcessingState_fromArgumentOption(option, alloc)
      defer _deleteOptionProcessingState(&proc_state)
      data_astrs, data_ok := &proc_state.data.([dynamic][dynamic]string)
      tc.expect(t, data_ok)
      input_trailer := "foo"
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, {}, {})
        tc.expect(t, !ok, "Expected not okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
      }
      {
        proc_out, ok := _processKeywordOption(option, &proc_state, input_trailer, {input_trailer, input_trailer})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 0)
        expected := [][dynamic]string{{input_trailer}}
        tc.expect(t, isequal_slice2(data_astrs^[:], expected[:]), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, data_astrs^))
      }
      {
        input_arg0 := "bar0"
        input_arg1 := "bar1"
        input_arg2 := "2222"
        proc_out, ok := _processKeywordOption(option, &proc_state, nil, {input_arg0, input_arg1, input_arg2})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 3)
        expected1 := [][dynamic]string{{input_trailer}, {input_arg0, input_arg1, input_arg2}}
        tc.expect(t, isequal_slice2(data_astrs^[:], expected1[:]), fmt.tprintf("\nExpected:%v\n     Got:%v", expected1, data_astrs^))
        // second confirms append of state
        proc_out, ok = _processKeywordOption(option, &proc_state, nil, {input_arg2, input_arg2})
        tc.expect(t, ok, "Expected okay")
        tc.expect(t, proc_out.trailer == nil)
        tc.expect(t, proc_out.num_consumed == 2)
        expected2 := [][dynamic]string{{input_trailer}, {input_arg0, input_arg1, input_arg2}, {input_arg2, input_arg2}}
        tc.expect(t, isequal_slice2(data_astrs^[:], expected2[:]), fmt.tprintf("\nExpected:%v\n     Got:%v", expected2, data_astrs^))
      }
    }
  }
}
