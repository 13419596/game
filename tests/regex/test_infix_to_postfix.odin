// Tests "game:regex/infix_to_postfix"
package test_regex

import "core:fmt"
import "core:io"
import "core:os"
import "core:testing"
import tc "tests:common"

num_monte :: 30

// convertInfixToPostfix :: proc(infix_tokens:[]ExpressionToken($T)) -> (out_postfix_tokens:[dynamic]ExpressionToken(T), ok:bool) {

runInfixToPostixTests :: proc(t: ^testing.T) {
  tc.expect(t, true)
}
