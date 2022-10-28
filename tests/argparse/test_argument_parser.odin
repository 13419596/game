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
  // test_addArgument(t)
  // test_getUsage(t)
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
  {
    ap, ap_ok := makeArgumentParser(prog = "prog", description = "desc", epilog = "epilog")
    defer deleteArgumentParser(&ap)
    {
      ok := addArgument(&ap, {"-v", "--verbose"}, ArgumentAction.StoreTrue)
      tc.expect(t, ok)
    }
    {
      /// should conflict with previous
      ok := addArgument(&ap, {"-v", "--verbose"}, ArgumentAction.StoreTrue)
      tc.expect(t, !ok)
    }
  }
  {
    // test again, but with temp_allocator
    ap, ap_ok := makeArgumentParser(prog = "prog", description = "desc", epilog = "epilog", allocator = context.temp_allocator)
    {
      ok := addArgument(&ap, {"-v", "--verbose"}, ArgumentAction.StoreTrue)
      tc.expect(t, ok)
    }
    {
      /// should conflict with previous
      ok := addArgument(&ap, {"-v", "--verbose"}, ArgumentAction.StoreTrue)
      tc.expect(t, !ok)
    }
  }
}

@(test)
test_getUsage :: proc(t: ^testing.T) {
  using argparse
  {
    expected_usage := "usage PROG [-h]"
    ap, ap_ok := makeArgumentParser(prog = "PROG", description = "desc", epilog = "epilog")
    defer deleteArgumentParser(&ap)
    usage := getUsage(&ap)
    tc.expect(t, expected_usage == usage, fmt.tprintf("Expected:\"%v\". Got:\"%v\"", expected_usage, usage))
  }
}
