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
  test_parseKnownArgs(t)
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
ParseKnownArgsTest :: struct {
  input:        []string,
  expected_ok:  bool,
  expected_out: argparse.ParsedData,
}

@(private = "file")
ParseKnownArgsFixture :: struct {
  make_argparser_args: MakeArgumentParserArgs,
  add_arg_args:        []AddArgumentArgs,
}


@(test)
test_parseKnownArgs :: proc(t: ^testing.T) {
  using argparse
  allocs := []runtime.Allocator{context.allocator, context.temp_allocator}
  for alloc in allocs {
    if false {
      ap, ap_ok := makeArgumentParser(prog = "PROG", description = "description", epilog = "EPILOG", allocator = alloc)
      defer deleteArgumentParser(&ap)
      out, ok := parseKnownArgs(&ap, {"-h"})
      defer deleteParsedOutput(&out)
      tc.expect(t, ok)
      tc.expect(t, out.should_quit)
    }
    if false {
      ap, ap_ok := makeArgumentParser(prog = "PROG", description = "description", epilog = "EPILOG", allocator = alloc)
      defer deleteArgumentParser(&ap)
      option, opt_ok := addArgument(self = &ap, action = .Version, flags = {"--version"})
      {
        out, ok := parseKnownArgs(&ap, {"--version"})
        defer deleteParsedOutput(&out)
        tc.expect(t, ok)
        tc.expect(t, out.should_quit)
        tc.expect(t, len(out.unknown) == 0)
      }
      {
        out, ok := parseKnownArgs(&ap, {"-version"})
        defer deleteParsedOutput(&out)
        tc.expect(t, ok)
        tc.expect(t, !out.should_quit)
        tc.expect(t, len(out.unknown) == 1)
      }
    }
    {
      ap, ap_ok := makeArgumentParser(prog = "PROG", description = "description", epilog = "EPILOG", allocator = alloc)
      defer deleteArgumentParser(&ap)
      option, opt_ok := addArgument(self = &ap, action = .Count, flags = {"-c", "--count"})
      tc.expect(t, opt_ok)
      {
        out, ok := parseKnownArgs(&ap, {"-c", "--count", "--cou"})
        defer deleteParsedOutput(&out)
        tc.expect(t, ok)
        tc.expect(t, !out.should_quit)
        tc.expect(t, len(out.unknown) == 0, fmt.tprintf("Expected no unknown. Got:%v", out.unknown))
        count, count_ok := out.data["count"].(int)
        tc.expect(t, count_ok)
        tc.expect(t, count == 3, fmt.tprintf("Expected: 3; Got:%v", count))
      }
    }
  }
}
