package re

RegexFlag :: enum {
  ASCII,
  // Make \w, \W, \b, \B, \d, \D, \s and \S perform ASCII-only matching instead of full Unicode matching. T
  // This is only meaningful for Unicode patterns, and is ignored for byte patterns. 
  DEBUG,
  // Display debug information about compiled expression. No corresponding inline flag.
  IGNORECASE,
  // Perform case-insensitive matching; expressions like [A-Z] will also match lowercase letters. Full Unicode matching 
  // (such as Ü matching ü) also works unless the re.ASCII flag is used to disable non-ASCII matches. The current locale 
  // does not change the effect of this flag unless the re.LOCALE flag is also used. Corresponds to the inline flag (?i).
  // Note that when the Unicode patterns [a-z] or [A-Z] are used in combination with the IGNORECASE flag, they will match
  // the 52 ASCII letters and 4 additional non-ASCII letters: ‘İ’ (U+0130, Latin capital letter I with dot above), ‘ı’ (U+0131, Latin small letter dotless i), ‘ſ’ (U+017F, Latin small letter long s) and ‘K’ (U+212A, Kelvin sign). If the ASCII flag is used, only letters ‘a’ to ‘z’ and ‘A’ to ‘Z’ are matched.
  MULTILINE,
  // When specified, the pattern character '^' matches at the beginning of the string and at the beginning of each line
  // (immediately following each newline); and the pattern character '$' matches at the end of the string and at the end
  // of each line (immediately preceding each newline). By default, '^' matches only at the beginning of the string, and '$' only at the end of the string and immediately before the newline (if any) at the end of the string. 
  DOTALL,
  // Make the '.' special character match any character at all, including a newline; without this flag, '.' will match 
  // anything except a newline.
  VERBOSE,
  // This flag allows you to write regular expressions that look nicer and are more readable by allowing you to visually
  // separate logical sections of the pattern and add comments. Whitespace within the pattern is ignored, except when in a character class, or when preceded by an unescaped backslash, or within tokens like *?, (?: or (?P<...>. For example, (? : and * ? are not allowed. When a line contains a # that is not in a character class and is not preceded by an unescaped backslash, all characters from the leftmost such # through the end of the line are ignored.
  // This means that the two following regular expression objects that match a decimal number are functionally equal:
  // 
  // a = re.compile(r"""\d +  # the integral part
  //                    \.    # the decimal point
  //                    \d *  # some fractional digits""", re.X)
  // b = re.compile(r"\d+\.\d*")
  // Corresponds to the inline flag (?x).
}

RegexFlags :: bit_set[RegexFlag]
