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
test_ArgumentParser :: proc(t: ^testing.T) {
  test_makeArgumentParser(t)
  test_addArgument(t)
  test_getUsage(t)
  test_getHelp(t)
  // test_getUnambiguousKeywordOption(t)
}

@(test)
test_makeArgumentParser :: proc(t: ^testing.T) {
  using argparse
  ap, ok := makeArgumentParser(prog = "prog", description = "desc", epilog = "epilog")
  tc.expect(t, ok)
  tc.expect(t, len(ap.prog) != 0)
  tc.expect(t, len(ap.description) != 0)
  tc.expect(t, len(ap.epilog) != 0)
  tc.expect(t, len(ap.options) == 1)
  deleteArgumentParser(&ap)
  tc.expect(t, len(ap.prog) == 0)
  tc.expect(t, len(ap.description) == 0)
  tc.expect(t, len(ap.epilog) == 0)
  tc.expect(t, len(ap.options) == 0)
}


@(test)
test_addArgument :: proc(t: ^testing.T) {
  using argparse
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      ap, ap_ok := makeArgumentParser(prog = "prog", description = "desc", epilog = "epilog", allocator = alloc)
      defer deleteArgumentParser(&ap)
      {
        arg, ok := addArgument(&ap, {"-v", "--verbose"}, ArgumentAction.StoreTrue)
        tc.expect(t, ok)
      }
      {
        /// should conflict with previous
        arg, ok := addArgument(&ap, {"-v"}, ArgumentAction.StoreTrue)
        tc.expect(t, !ok)
      }
      {
        /// should conflict with previous
        arg, ok := addArgument(&ap, {"--verbose"}, ArgumentAction.StoreTrue)
        tc.expect(t, !ok)
      }
    }
    {
      // test again, but with temp_allocator
      ap, ap_ok := makeArgumentParser(prog = "prog", description = "desc", epilog = "epilog", allocator = alloc)
      {
        arg, ok := addArgument(&ap, {"-v", "--verbose"}, ArgumentAction.StoreTrue)
        tc.expect(t, ok)
      }
      {
        /// should conflict with previous
        arg, ok := addArgument(&ap, {"-v", "--verbose"}, ArgumentAction.StoreTrue)
        tc.expect(t, !ok)
      }
    }
  }
}

@(test)
test_getUsage :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      expected_usage := "usage PROG [-h] --long LONG pos pos pos"
      ap, ap_ok := makeArgumentParser(prog = "PROG", description = "desc", epilog = "epilog", allocator = alloc)
      defer deleteArgumentParser(&ap)
      addArgument(self = &ap, flags = {"--long"}, required = true, nargs = 1)
      addArgument(self = &ap, flags = {"pos"}, required = true, nargs = 3)
      usage := getUsage(&ap)
      tc.expect(t, expected_usage == usage, fmt.tprintf("\nExpected:%q.\nGot     :%q", expected_usage, usage))
    }
  }
}


@(test)
test_getHelp :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      expected_help := "usage PROG [-h] --long LONG pos pos pos\n\ndescription\n\npositional arguments:\n  pos                   \n\nkeyword arguments:\n  -h, --help            show this help message and exit\n  --long LONG           \n\nEPILOG"
      ap, ap_ok := makeArgumentParser(prog = "PROG", description = "description", epilog = "EPILOG", allocator = alloc)
      defer deleteArgumentParser(&ap)
      addArgument(self = &ap, flags = {"--long"}, required = true, nargs = 1)
      addArgument(self = &ap, flags = {"pos"}, required = true, nargs = 3)
      help := getHelp(&ap)
      tc.expect(t, len(expected_help) == len(help), fmt.tprintf("Expected len:%v Got len:%v", len(expected_help), len(help)))
      tc.expect(t, expected_help == help, fmt.tprintf("\nExpected:\"\"\"\n%v\n\"\"\"\nGot:\"\"\"\n%v\n\"\"\"", expected_help, help))
    }
  }
}

/////////////////////////////////////////
/*
@(test)
test_getUnambiguousKeywordOption :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    {
      ap, ap_ok := makeArgumentParser(prog = "PROG", description = "description", epilog = "EPILOG", allocator = alloc)
      defer deleteArgumentParser(&ap)
      tc.expect(t, ap_ok)
      addArgument(&ap, {"--abc0"})
      addArgument(&ap, {"--abc1"})
      addArgument(&ap, {"--abc2"})
      addArgument(&ap, {"--abbrieviation", "--abby"})
      fuko := _getUnambiguousKeywordOption(&ap, "--abc0")
      tc.expect(t, fuko.option != nil)
      fuko = _getUnambiguousKeywordOption(&ap, "--abc")
      tc.expect(t, fuko.option == nil)
      fuko = _getUnambiguousKeywordOption(&ap, "--abbriev")
      tc.expect(t, fuko.option != nil)
      tc.expect(t, len(fuko.arg) <= len(fuko.keyword))
      fuko = _getUnambiguousKeywordOption(&ap, "--abbrieviation")
      tc.expect(t, fuko.option != nil)
      tc.expect(t, len(fuko.arg) == len(fuko.keyword))
    }
  }
}

*/
