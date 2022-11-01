// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_argparse

import "core:fmt"
import "core:log"
import "core:runtime"
import "core:testing"
import "game:argparse"
import tc "tests:common"


@(test)
test_ArgParse_Keyword :: proc(t: ^testing.T) {
  test_determineKeywordOption(t)
  test_makeOptionProcessingState(t)
  test_processKeywordOption(t)
}

@(test)
test_determineKeywordOption :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      addArgument(self = &ap, flags = {"-a"})
      input := "-a"
      output, ok := _determineKeywordOption(&ap._kw_trie, input)
      tc.expect(t, ok, "Expected ok")
      expected := _FoundKeywordOption(string) {
        arg                  = input,
        flag_type            = .Short,
        value                = "a",
        head                 = "-a",
        tail                 = nil,
        removed_equal_prefix = false,
      }
      tc.expect(t, _isequal_FoundKeywordOption(&output, &expected), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, output))
    }
    {
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      addArgument(self = &ap, flags = {"-a"})
      input := "-a=0"
      output, ok := _determineKeywordOption(&ap._kw_trie, input)
      expected := _FoundKeywordOption(string) {
        arg                  = input,
        flag_type            = .Short,
        value                = "a",
        head                 = "-a",
        tail                 = "0",
        removed_equal_prefix = true,
      }
      tc.expect(t, ok, "Expected ok")
      tc.expect(t, _isequal_FoundKeywordOption(&output, &expected), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, output))
    }
    {
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      addArgument(self = &ap, flags = {"-a"})
      input := "-a77"
      output, ok := _determineKeywordOption(&ap._kw_trie, input)
      expected := _FoundKeywordOption(string) {
        arg                  = input,
        flag_type            = .Short,
        value                = "a",
        head                 = "-a",
        tail                 = "77",
        removed_equal_prefix = false,
      }
      tc.expect(t, ok, "Expected ok")
      tc.expect(t, _isequal_FoundKeywordOption(&output, &expected), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, output))
    }
    {
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      addArgument(self = &ap, flags = {"-a"})
      addArgument(self = &ap, flags = {"-ab"})
      input := "-a"
      output, ok := _determineKeywordOption(&ap._kw_trie, input)
      tc.expect(t, ok, "Expected ok")
      expected := _FoundKeywordOption(string) {
        arg                  = input,
        flag_type            = .Short,
        value                = "a",
        head                 = input,
        tail                 = nil,
        removed_equal_prefix = false,
      }
      tc.expect(t, _isequal_FoundKeywordOption(&output, &expected), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, output))
    }
    if false {
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      addArgument(self = &ap, flags = {"-a"})
      addArgument(self = &ap, flags = {"-ab"})
      input := "-a=9"
      output, ok := _determineKeywordOption(&ap._kw_trie, input)
      tc.expect(t, ok, fmt.tprintf("Expected ok"))
      expected := _FoundKeywordOption(string) {
        arg                  = input,
        flag_type            = .Short,
        value                = "a",
        head                 = "-a",
        tail                 = "9",
        removed_equal_prefix = true,
      }
      tc.expect(t, _isequal_FoundKeywordOption(&output, &expected), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, output))
    }
    ////////
    // Long flags
    {
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      addArgument(self = &ap, flags = {"--a"})
      input := "--a"
      output, ok := _determineKeywordOption(&ap._kw_trie, input)
      tc.expect(t, ok, "Expected ok")
      expected := _FoundKeywordOption(string) {
        arg                  = input,
        flag_type            = .Long,
        value                = "a",
        head                 = "--a",
        tail                 = nil,
        removed_equal_prefix = false,
      }
      tc.expect(t, _isequal_FoundKeywordOption(&output, &expected), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, output))
    }
    {
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      addArgument(self = &ap, flags = {"--a"})
      input := "--a=0"
      output, ok := _determineKeywordOption(&ap._kw_trie, input)
      expected := _FoundKeywordOption(string) {
        arg                  = input,
        flag_type            = .Long,
        value                = "a",
        head                 = "--a",
        tail                 = "0",
        removed_equal_prefix = true,
      }
      tc.expect(t, ok, "Expected ok")
      tc.expect(t, _isequal_FoundKeywordOption(&output, &expected), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, output))
    }
    {
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      addArgument(self = &ap, flags = {"--a"})
      input := "--a77"
      output, ok := _determineKeywordOption(&ap._kw_trie, input)
      expected := _FoundKeywordOption(string) {
        arg                  = input,
        flag_type            = .Long,
        value                = "a",
        head                 = "--a",
        tail                 = "77",
        removed_equal_prefix = false,
      }
      tc.expect(t, ok, "Expected ok")
      tc.expect(t, _isequal_FoundKeywordOption(&output, &expected), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, output))
    }
    {
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      addArgument(self = &ap, flags = {"--a"})
      addArgument(self = &ap, flags = {"-ab"})
      input := "--a"
      output, ok := _determineKeywordOption(&ap._kw_trie, input)
      tc.expect(t, ok, "Expected ok")
      expected := _FoundKeywordOption(string) {
        arg                  = input,
        flag_type            = .Long,
        value                = "a",
        head                 = input,
        tail                 = nil,
        removed_equal_prefix = false,
      }
      tc.expect(t, _isequal_FoundKeywordOption(&output, &expected), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, output))
    }
    {
      ap, ap_ok := makeArgumentParser(prog = "TEST", description = "description", epilog = "EPILOG", allocator = alloc, add_help = false)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      addArgument(self = &ap, flags = {"--a"})
      addArgument(self = &ap, flags = {"-ab"})
      input := "--a=9"
      output, ok := _determineKeywordOption(&ap._kw_trie, input)
      tc.expect(t, ok, fmt.tprintf("Expected ok"))
      expected := _FoundKeywordOption(string) {
        arg                  = input,
        flag_type            = .Long,
        value                = "a",
        head                 = "--a",
        tail                 = "9",
        removed_equal_prefix = true,
      }
      tc.expect(t, _isequal_FoundKeywordOption(&output, &expected), fmt.tprintf("\nExpected:%v\n     Got:%v", expected, output))
    }
  }
}

@(test)
test_makeOptionProcessingState :: proc(t: ^testing.T) {
  using argparse
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
        case [dynamic]string:
          append(&data, "string data")
          append(&data, "string data")
          append(&data, "string data")
        case [dynamic][]string:
          vals := make([dynamic]string, 1)
          vals[0] = "data"
          append(&data, vals[:])
          vals = make([dynamic]string, 1)
          vals[0] = "data"
          append(&data, vals[:])
        }
        _deleteOptionProcessingState(&state)
        tc.expect(t, state.data == nil)
      }
    }
  }
}


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
    case .Append:
      tc.expect(t, false, "untested option")
    case .Count:
      test_processKeywordOption_Count(t)
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
        // second confirms overwrite of state
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
        // second confirms overwrite of state
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
        // second confirms overwrite of state
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
        // second confirms overwrite of state
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
