// Tests "game:regex/infix_to_postfix"
// Must be run with `-collection:tests=` flag
package test_trie

import "core:fmt"
import "core:log"
import "core:strings"
import "core:runtime"
import "core:testing"
import "game:trie"
import tc "tests:common"

main :: proc() {
  t := testing.T{}
  console_logger := log.create_console_logger()
  defer log.destroy_file_logger(&console_logger)
  multi_logger := log.create_multi_logger(console_logger)
  defer log.destroy_multi_logger(&multi_logger)
  context.logger = multi_logger

  test_TrieNode(&t)
  test_Trie(&t)
  tc.report(&t)
}
