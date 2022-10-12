package re

ShortHandClass :: enum {
  Flag_W,
  Flag_D,
  Flag_S,
  Flag_B,
  // Before the first character in the string, if the first character is a word character.
  // After the last character in the string, if the last character is a word character.
  // Between two characters in the string, where one is a word character and the other is not a word character.
  Flag_Dot,
}

/* Generated from following script
```python
import re
from typing import Sequence, Tuple

def getBreakPointsInSequences(points: Sequence[int]) -> Sequence[Tuple[int,int]]:
  if not points:
    return []
  ##
  out = []
  start = points[0]
  prev_point = points[0]
  for point in points[1:]:
    if prev_point+1!=point:
      out.append((start,prev_point,))
      start = point
    ##
    prev_point = point
  ##
  # Add last group
  out.append((start,points[-1]))
  return out
##

def writeOdinBreakpointChecks(breakpoints:Sequence[Tuple[int,int]], function_name:str, indent:str='  ', line_prefix:str='', doc_comment:str = '') -> str:
  out = [f'{function_name} :: proc(rn:rune) -> bool {{', ]
  if doc_comment:
    out.append(indent*1 + '// ' + doc_comment)
  ##
  if len(breakpoints)>4:
    out.append(indent*1 + '// TODO optimize check - binary searchspeed up check')
  ##
  out.append(indent*1 + 'switch u32(rn) {')
  num_breakpoints = len(breakpoints)
  for idx, (lb, rb) in enumerate(breakpoints):
    if lb!=rb:
      line = indent*2 + f'case {lb}..={rb}:'
    else:
      line = indent*2 + f'case {lb}:'
    ##
    if idx+1<num_breakpoints:
      line += ' fallthrough'
    else:
      line += ' return true'
    ##
    out.append(line)
  ##
  out.append(indent*1 + '}')
  out.append(indent*1 + 'return false')
  # all as one return statement
  # groups = [f'({lb}<=v && v<={rb})' if lb!=rb else f'(v=={lb})' for lb,rb in breakpoints]
  # return_value = ' || '.join(groups)
  # if len(groups)>1:
  #   return_value = f'({return_value})'
  # ##
  # out.append(indent*1 + 'return ' + return_value)
  out.append('}')
  return '\n'.join(line_prefix+line for line in out)
##


MAX_UTF8 = 0x10FFFF
all_utf8 = [chr(x) for x in range(MAX_UTF8+1)]
patterns = [('whitespace',r'\s'),('word',r'\w'),('Digit', r'\d'),]

odin_funcs = []
for name, pattern in patterns:
  matches = [ch for ch in all_utf8 if re.match(pattern,ch)]
  # print(f'Pattern {name} {pattern!r} -- matches:{len(matches)} inverse:{len(all_utf8)-len(matches)}')
  utf8_points = [ord(ch) for ch in matches]
  utf8_bps = getBreakPointsInSequences(utf8_points)
  code = writeOdinBreakpointChecks(utf8_bps,f'isShorthand{name.title()}_utf8', doc_comment=f'matches {name} regex "{pattern}"')
  odin_funcs.append(code)
  ascii_points = [ord(ch) for ch in matches if ch.isascii()]
  ascii_bps = getBreakPointsInSequences(ascii_points)
  code = writeOdinBreakpointChecks(ascii_bps,f'isShorthand{name.title()}_ascii', doc_comment=f'matches {name} regex "{pattern}" flag="ASCII"')
  odin_funcs.append(code)
##

print('\n\n'.join(odin_funcs))
```*/

isShorthandWhitespace_utf8 :: proc(rn: rune) -> bool {
  // matches whitespace regex "\s"
  // TODO optimize check - binary searchspeed up check
  switch u32(rn) {
  case 9 ..= 13:
    fallthrough
  case 28 ..= 32:
    fallthrough
  case 133:
    fallthrough
  case 160:
    fallthrough
  case 5760:
    fallthrough
  case 8192 ..= 8202:
    fallthrough
  case 8232 ..= 8233:
    fallthrough
  case 8239:
    fallthrough
  case 8287:
    fallthrough
  case 12288:
    return true
  }
  return false
}

isShorthandWhitespace_ascii :: proc(rn: rune) -> bool {
  // matches whitespace regex "\s" flag="ASCII"
  switch u32(rn) {
  case 9 ..= 13:
    fallthrough
  case 28 ..= 32:
    return true
  }
  return false
}

isShorthandWord_utf8 :: proc(rn: rune) -> bool {
  // matches word regex "\w"
  // TODO optimize check - binary searchspeed up check
  switch u32(rn) {
  case 48 ..= 57:
    fallthrough
  case 65 ..= 90:
    fallthrough
  case 95:
    fallthrough
  case 97 ..= 122:
    fallthrough
  case 170:
    fallthrough
  case 178 ..= 179:
    fallthrough
  case 181:
    fallthrough
  case 185 ..= 186:
    fallthrough
  case 188 ..= 190:
    fallthrough
  case 192 ..= 214:
    fallthrough
  case 216 ..= 246:
    fallthrough
  case 248 ..= 705:
    fallthrough
  case 710 ..= 721:
    fallthrough
  case 736 ..= 740:
    fallthrough
  case 748:
    fallthrough
  case 750:
    fallthrough
  case 880 ..= 884:
    fallthrough
  case 886 ..= 887:
    fallthrough
  case 890 ..= 893:
    fallthrough
  case 895:
    fallthrough
  case 902:
    fallthrough
  case 904 ..= 906:
    fallthrough
  case 908:
    fallthrough
  case 910 ..= 929:
    fallthrough
  case 931 ..= 1013:
    fallthrough
  case 1015 ..= 1153:
    fallthrough
  case 1162 ..= 1327:
    fallthrough
  case 1329 ..= 1366:
    fallthrough
  case 1369:
    fallthrough
  case 1376 ..= 1416:
    fallthrough
  case 1488 ..= 1514:
    fallthrough
  case 1519 ..= 1522:
    fallthrough
  case 1568 ..= 1610:
    fallthrough
  case 1632 ..= 1641:
    fallthrough
  case 1646 ..= 1647:
    fallthrough
  case 1649 ..= 1747:
    fallthrough
  case 1749:
    fallthrough
  case 1765 ..= 1766:
    fallthrough
  case 1774 ..= 1788:
    fallthrough
  case 1791:
    fallthrough
  case 1808:
    fallthrough
  case 1810 ..= 1839:
    fallthrough
  case 1869 ..= 1957:
    fallthrough
  case 1969:
    fallthrough
  case 1984 ..= 2026:
    fallthrough
  case 2036 ..= 2037:
    fallthrough
  case 2042:
    fallthrough
  case 2048 ..= 2069:
    fallthrough
  case 2074:
    fallthrough
  case 2084:
    fallthrough
  case 2088:
    fallthrough
  case 2112 ..= 2136:
    fallthrough
  case 2144 ..= 2154:
    fallthrough
  case 2208 ..= 2228:
    fallthrough
  case 2230 ..= 2247:
    fallthrough
  case 2308 ..= 2361:
    fallthrough
  case 2365:
    fallthrough
  case 2384:
    fallthrough
  case 2392 ..= 2401:
    fallthrough
  case 2406 ..= 2415:
    fallthrough
  case 2417 ..= 2432:
    fallthrough
  case 2437 ..= 2444:
    fallthrough
  case 2447 ..= 2448:
    fallthrough
  case 2451 ..= 2472:
    fallthrough
  case 2474 ..= 2480:
    fallthrough
  case 2482:
    fallthrough
  case 2486 ..= 2489:
    fallthrough
  case 2493:
    fallthrough
  case 2510:
    fallthrough
  case 2524 ..= 2525:
    fallthrough
  case 2527 ..= 2529:
    fallthrough
  case 2534 ..= 2545:
    fallthrough
  case 2548 ..= 2553:
    fallthrough
  case 2556:
    fallthrough
  case 2565 ..= 2570:
    fallthrough
  case 2575 ..= 2576:
    fallthrough
  case 2579 ..= 2600:
    fallthrough
  case 2602 ..= 2608:
    fallthrough
  case 2610 ..= 2611:
    fallthrough
  case 2613 ..= 2614:
    fallthrough
  case 2616 ..= 2617:
    fallthrough
  case 2649 ..= 2652:
    fallthrough
  case 2654:
    fallthrough
  case 2662 ..= 2671:
    fallthrough
  case 2674 ..= 2676:
    fallthrough
  case 2693 ..= 2701:
    fallthrough
  case 2703 ..= 2705:
    fallthrough
  case 2707 ..= 2728:
    fallthrough
  case 2730 ..= 2736:
    fallthrough
  case 2738 ..= 2739:
    fallthrough
  case 2741 ..= 2745:
    fallthrough
  case 2749:
    fallthrough
  case 2768:
    fallthrough
  case 2784 ..= 2785:
    fallthrough
  case 2790 ..= 2799:
    fallthrough
  case 2809:
    fallthrough
  case 2821 ..= 2828:
    fallthrough
  case 2831 ..= 2832:
    fallthrough
  case 2835 ..= 2856:
    fallthrough
  case 2858 ..= 2864:
    fallthrough
  case 2866 ..= 2867:
    fallthrough
  case 2869 ..= 2873:
    fallthrough
  case 2877:
    fallthrough
  case 2908 ..= 2909:
    fallthrough
  case 2911 ..= 2913:
    fallthrough
  case 2918 ..= 2927:
    fallthrough
  case 2929 ..= 2935:
    fallthrough
  case 2947:
    fallthrough
  case 2949 ..= 2954:
    fallthrough
  case 2958 ..= 2960:
    fallthrough
  case 2962 ..= 2965:
    fallthrough
  case 2969 ..= 2970:
    fallthrough
  case 2972:
    fallthrough
  case 2974 ..= 2975:
    fallthrough
  case 2979 ..= 2980:
    fallthrough
  case 2984 ..= 2986:
    fallthrough
  case 2990 ..= 3001:
    fallthrough
  case 3024:
    fallthrough
  case 3046 ..= 3058:
    fallthrough
  case 3077 ..= 3084:
    fallthrough
  case 3086 ..= 3088:
    fallthrough
  case 3090 ..= 3112:
    fallthrough
  case 3114 ..= 3129:
    fallthrough
  case 3133:
    fallthrough
  case 3160 ..= 3162:
    fallthrough
  case 3168 ..= 3169:
    fallthrough
  case 3174 ..= 3183:
    fallthrough
  case 3192 ..= 3198:
    fallthrough
  case 3200:
    fallthrough
  case 3205 ..= 3212:
    fallthrough
  case 3214 ..= 3216:
    fallthrough
  case 3218 ..= 3240:
    fallthrough
  case 3242 ..= 3251:
    fallthrough
  case 3253 ..= 3257:
    fallthrough
  case 3261:
    fallthrough
  case 3294:
    fallthrough
  case 3296 ..= 3297:
    fallthrough
  case 3302 ..= 3311:
    fallthrough
  case 3313 ..= 3314:
    fallthrough
  case 3332 ..= 3340:
    fallthrough
  case 3342 ..= 3344:
    fallthrough
  case 3346 ..= 3386:
    fallthrough
  case 3389:
    fallthrough
  case 3406:
    fallthrough
  case 3412 ..= 3414:
    fallthrough
  case 3416 ..= 3425:
    fallthrough
  case 3430 ..= 3448:
    fallthrough
  case 3450 ..= 3455:
    fallthrough
  case 3461 ..= 3478:
    fallthrough
  case 3482 ..= 3505:
    fallthrough
  case 3507 ..= 3515:
    fallthrough
  case 3517:
    fallthrough
  case 3520 ..= 3526:
    fallthrough
  case 3558 ..= 3567:
    fallthrough
  case 3585 ..= 3632:
    fallthrough
  case 3634 ..= 3635:
    fallthrough
  case 3648 ..= 3654:
    fallthrough
  case 3664 ..= 3673:
    fallthrough
  case 3713 ..= 3714:
    fallthrough
  case 3716:
    fallthrough
  case 3718 ..= 3722:
    fallthrough
  case 3724 ..= 3747:
    fallthrough
  case 3749:
    fallthrough
  case 3751 ..= 3760:
    fallthrough
  case 3762 ..= 3763:
    fallthrough
  case 3773:
    fallthrough
  case 3776 ..= 3780:
    fallthrough
  case 3782:
    fallthrough
  case 3792 ..= 3801:
    fallthrough
  case 3804 ..= 3807:
    fallthrough
  case 3840:
    fallthrough
  case 3872 ..= 3891:
    fallthrough
  case 3904 ..= 3911:
    fallthrough
  case 3913 ..= 3948:
    fallthrough
  case 3976 ..= 3980:
    fallthrough
  case 4096 ..= 4138:
    fallthrough
  case 4159 ..= 4169:
    fallthrough
  case 4176 ..= 4181:
    fallthrough
  case 4186 ..= 4189:
    fallthrough
  case 4193:
    fallthrough
  case 4197 ..= 4198:
    fallthrough
  case 4206 ..= 4208:
    fallthrough
  case 4213 ..= 4225:
    fallthrough
  case 4238:
    fallthrough
  case 4240 ..= 4249:
    fallthrough
  case 4256 ..= 4293:
    fallthrough
  case 4295:
    fallthrough
  case 4301:
    fallthrough
  case 4304 ..= 4346:
    fallthrough
  case 4348 ..= 4680:
    fallthrough
  case 4682 ..= 4685:
    fallthrough
  case 4688 ..= 4694:
    fallthrough
  case 4696:
    fallthrough
  case 4698 ..= 4701:
    fallthrough
  case 4704 ..= 4744:
    fallthrough
  case 4746 ..= 4749:
    fallthrough
  case 4752 ..= 4784:
    fallthrough
  case 4786 ..= 4789:
    fallthrough
  case 4792 ..= 4798:
    fallthrough
  case 4800:
    fallthrough
  case 4802 ..= 4805:
    fallthrough
  case 4808 ..= 4822:
    fallthrough
  case 4824 ..= 4880:
    fallthrough
  case 4882 ..= 4885:
    fallthrough
  case 4888 ..= 4954:
    fallthrough
  case 4969 ..= 4988:
    fallthrough
  case 4992 ..= 5007:
    fallthrough
  case 5024 ..= 5109:
    fallthrough
  case 5112 ..= 5117:
    fallthrough
  case 5121 ..= 5740:
    fallthrough
  case 5743 ..= 5759:
    fallthrough
  case 5761 ..= 5786:
    fallthrough
  case 5792 ..= 5866:
    fallthrough
  case 5870 ..= 5880:
    fallthrough
  case 5888 ..= 5900:
    fallthrough
  case 5902 ..= 5905:
    fallthrough
  case 5920 ..= 5937:
    fallthrough
  case 5952 ..= 5969:
    fallthrough
  case 5984 ..= 5996:
    fallthrough
  case 5998 ..= 6000:
    fallthrough
  case 6016 ..= 6067:
    fallthrough
  case 6103:
    fallthrough
  case 6108:
    fallthrough
  case 6112 ..= 6121:
    fallthrough
  case 6128 ..= 6137:
    fallthrough
  case 6160 ..= 6169:
    fallthrough
  case 6176 ..= 6264:
    fallthrough
  case 6272 ..= 6276:
    fallthrough
  case 6279 ..= 6312:
    fallthrough
  case 6314:
    fallthrough
  case 6320 ..= 6389:
    fallthrough
  case 6400 ..= 6430:
    fallthrough
  case 6470 ..= 6509:
    fallthrough
  case 6512 ..= 6516:
    fallthrough
  case 6528 ..= 6571:
    fallthrough
  case 6576 ..= 6601:
    fallthrough
  case 6608 ..= 6618:
    fallthrough
  case 6656 ..= 6678:
    fallthrough
  case 6688 ..= 6740:
    fallthrough
  case 6784 ..= 6793:
    fallthrough
  case 6800 ..= 6809:
    fallthrough
  case 6823:
    fallthrough
  case 6917 ..= 6963:
    fallthrough
  case 6981 ..= 6987:
    fallthrough
  case 6992 ..= 7001:
    fallthrough
  case 7043 ..= 7072:
    fallthrough
  case 7086 ..= 7141:
    fallthrough
  case 7168 ..= 7203:
    fallthrough
  case 7232 ..= 7241:
    fallthrough
  case 7245 ..= 7293:
    fallthrough
  case 7296 ..= 7304:
    fallthrough
  case 7312 ..= 7354:
    fallthrough
  case 7357 ..= 7359:
    fallthrough
  case 7401 ..= 7404:
    fallthrough
  case 7406 ..= 7411:
    fallthrough
  case 7413 ..= 7414:
    fallthrough
  case 7418:
    fallthrough
  case 7424 ..= 7615:
    fallthrough
  case 7680 ..= 7957:
    fallthrough
  case 7960 ..= 7965:
    fallthrough
  case 7968 ..= 8005:
    fallthrough
  case 8008 ..= 8013:
    fallthrough
  case 8016 ..= 8023:
    fallthrough
  case 8025:
    fallthrough
  case 8027:
    fallthrough
  case 8029:
    fallthrough
  case 8031 ..= 8061:
    fallthrough
  case 8064 ..= 8116:
    fallthrough
  case 8118 ..= 8124:
    fallthrough
  case 8126:
    fallthrough
  case 8130 ..= 8132:
    fallthrough
  case 8134 ..= 8140:
    fallthrough
  case 8144 ..= 8147:
    fallthrough
  case 8150 ..= 8155:
    fallthrough
  case 8160 ..= 8172:
    fallthrough
  case 8178 ..= 8180:
    fallthrough
  case 8182 ..= 8188:
    fallthrough
  case 8304 ..= 8305:
    fallthrough
  case 8308 ..= 8313:
    fallthrough
  case 8319 ..= 8329:
    fallthrough
  case 8336 ..= 8348:
    fallthrough
  case 8450:
    fallthrough
  case 8455:
    fallthrough
  case 8458 ..= 8467:
    fallthrough
  case 8469:
    fallthrough
  case 8473 ..= 8477:
    fallthrough
  case 8484:
    fallthrough
  case 8486:
    fallthrough
  case 8488:
    fallthrough
  case 8490 ..= 8493:
    fallthrough
  case 8495 ..= 8505:
    fallthrough
  case 8508 ..= 8511:
    fallthrough
  case 8517 ..= 8521:
    fallthrough
  case 8526:
    fallthrough
  case 8528 ..= 8585:
    fallthrough
  case 9312 ..= 9371:
    fallthrough
  case 9450 ..= 9471:
    fallthrough
  case 10102 ..= 10131:
    fallthrough
  case 11264 ..= 11310:
    fallthrough
  case 11312 ..= 11358:
    fallthrough
  case 11360 ..= 11492:
    fallthrough
  case 11499 ..= 11502:
    fallthrough
  case 11506 ..= 11507:
    fallthrough
  case 11517:
    fallthrough
  case 11520 ..= 11557:
    fallthrough
  case 11559:
    fallthrough
  case 11565:
    fallthrough
  case 11568 ..= 11623:
    fallthrough
  case 11631:
    fallthrough
  case 11648 ..= 11670:
    fallthrough
  case 11680 ..= 11686:
    fallthrough
  case 11688 ..= 11694:
    fallthrough
  case 11696 ..= 11702:
    fallthrough
  case 11704 ..= 11710:
    fallthrough
  case 11712 ..= 11718:
    fallthrough
  case 11720 ..= 11726:
    fallthrough
  case 11728 ..= 11734:
    fallthrough
  case 11736 ..= 11742:
    fallthrough
  case 11823:
    fallthrough
  case 12293 ..= 12295:
    fallthrough
  case 12321 ..= 12329:
    fallthrough
  case 12337 ..= 12341:
    fallthrough
  case 12344 ..= 12348:
    fallthrough
  case 12353 ..= 12438:
    fallthrough
  case 12445 ..= 12447:
    fallthrough
  case 12449 ..= 12538:
    fallthrough
  case 12540 ..= 12543:
    fallthrough
  case 12549 ..= 12591:
    fallthrough
  case 12593 ..= 12686:
    fallthrough
  case 12690 ..= 12693:
    fallthrough
  case 12704 ..= 12735:
    fallthrough
  case 12784 ..= 12799:
    fallthrough
  case 12832 ..= 12841:
    fallthrough
  case 12872 ..= 12879:
    fallthrough
  case 12881 ..= 12895:
    fallthrough
  case 12928 ..= 12937:
    fallthrough
  case 12977 ..= 12991:
    fallthrough
  case 13312 ..= 19903:
    fallthrough
  case 19968 ..= 40956:
    fallthrough
  case 40960 ..= 42124:
    fallthrough
  case 42192 ..= 42237:
    fallthrough
  case 42240 ..= 42508:
    fallthrough
  case 42512 ..= 42539:
    fallthrough
  case 42560 ..= 42606:
    fallthrough
  case 42623 ..= 42653:
    fallthrough
  case 42656 ..= 42735:
    fallthrough
  case 42775 ..= 42783:
    fallthrough
  case 42786 ..= 42888:
    fallthrough
  case 42891 ..= 42943:
    fallthrough
  case 42946 ..= 42954:
    fallthrough
  case 42997 ..= 43009:
    fallthrough
  case 43011 ..= 43013:
    fallthrough
  case 43015 ..= 43018:
    fallthrough
  case 43020 ..= 43042:
    fallthrough
  case 43056 ..= 43061:
    fallthrough
  case 43072 ..= 43123:
    fallthrough
  case 43138 ..= 43187:
    fallthrough
  case 43216 ..= 43225:
    fallthrough
  case 43250 ..= 43255:
    fallthrough
  case 43259:
    fallthrough
  case 43261 ..= 43262:
    fallthrough
  case 43264 ..= 43301:
    fallthrough
  case 43312 ..= 43334:
    fallthrough
  case 43360 ..= 43388:
    fallthrough
  case 43396 ..= 43442:
    fallthrough
  case 43471 ..= 43481:
    fallthrough
  case 43488 ..= 43492:
    fallthrough
  case 43494 ..= 43518:
    fallthrough
  case 43520 ..= 43560:
    fallthrough
  case 43584 ..= 43586:
    fallthrough
  case 43588 ..= 43595:
    fallthrough
  case 43600 ..= 43609:
    fallthrough
  case 43616 ..= 43638:
    fallthrough
  case 43642:
    fallthrough
  case 43646 ..= 43695:
    fallthrough
  case 43697:
    fallthrough
  case 43701 ..= 43702:
    fallthrough
  case 43705 ..= 43709:
    fallthrough
  case 43712:
    fallthrough
  case 43714:
    fallthrough
  case 43739 ..= 43741:
    fallthrough
  case 43744 ..= 43754:
    fallthrough
  case 43762 ..= 43764:
    fallthrough
  case 43777 ..= 43782:
    fallthrough
  case 43785 ..= 43790:
    fallthrough
  case 43793 ..= 43798:
    fallthrough
  case 43808 ..= 43814:
    fallthrough
  case 43816 ..= 43822:
    fallthrough
  case 43824 ..= 43866:
    fallthrough
  case 43868 ..= 43881:
    fallthrough
  case 43888 ..= 44002:
    fallthrough
  case 44016 ..= 44025:
    fallthrough
  case 44032 ..= 55203:
    fallthrough
  case 55216 ..= 55238:
    fallthrough
  case 55243 ..= 55291:
    fallthrough
  case 63744 ..= 64109:
    fallthrough
  case 64112 ..= 64217:
    fallthrough
  case 64256 ..= 64262:
    fallthrough
  case 64275 ..= 64279:
    fallthrough
  case 64285:
    fallthrough
  case 64287 ..= 64296:
    fallthrough
  case 64298 ..= 64310:
    fallthrough
  case 64312 ..= 64316:
    fallthrough
  case 64318:
    fallthrough
  case 64320 ..= 64321:
    fallthrough
  case 64323 ..= 64324:
    fallthrough
  case 64326 ..= 64433:
    fallthrough
  case 64467 ..= 64829:
    fallthrough
  case 64848 ..= 64911:
    fallthrough
  case 64914 ..= 64967:
    fallthrough
  case 65008 ..= 65019:
    fallthrough
  case 65136 ..= 65140:
    fallthrough
  case 65142 ..= 65276:
    fallthrough
  case 65296 ..= 65305:
    fallthrough
  case 65313 ..= 65338:
    fallthrough
  case 65345 ..= 65370:
    fallthrough
  case 65382 ..= 65470:
    fallthrough
  case 65474 ..= 65479:
    fallthrough
  case 65482 ..= 65487:
    fallthrough
  case 65490 ..= 65495:
    fallthrough
  case 65498 ..= 65500:
    fallthrough
  case 65536 ..= 65547:
    fallthrough
  case 65549 ..= 65574:
    fallthrough
  case 65576 ..= 65594:
    fallthrough
  case 65596 ..= 65597:
    fallthrough
  case 65599 ..= 65613:
    fallthrough
  case 65616 ..= 65629:
    fallthrough
  case 65664 ..= 65786:
    fallthrough
  case 65799 ..= 65843:
    fallthrough
  case 65856 ..= 65912:
    fallthrough
  case 65930 ..= 65931:
    fallthrough
  case 66176 ..= 66204:
    fallthrough
  case 66208 ..= 66256:
    fallthrough
  case 66273 ..= 66299:
    fallthrough
  case 66304 ..= 66339:
    fallthrough
  case 66349 ..= 66378:
    fallthrough
  case 66384 ..= 66421:
    fallthrough
  case 66432 ..= 66461:
    fallthrough
  case 66464 ..= 66499:
    fallthrough
  case 66504 ..= 66511:
    fallthrough
  case 66513 ..= 66517:
    fallthrough
  case 66560 ..= 66717:
    fallthrough
  case 66720 ..= 66729:
    fallthrough
  case 66736 ..= 66771:
    fallthrough
  case 66776 ..= 66811:
    fallthrough
  case 66816 ..= 66855:
    fallthrough
  case 66864 ..= 66915:
    fallthrough
  case 67072 ..= 67382:
    fallthrough
  case 67392 ..= 67413:
    fallthrough
  case 67424 ..= 67431:
    fallthrough
  case 67584 ..= 67589:
    fallthrough
  case 67592:
    fallthrough
  case 67594 ..= 67637:
    fallthrough
  case 67639 ..= 67640:
    fallthrough
  case 67644:
    fallthrough
  case 67647 ..= 67669:
    fallthrough
  case 67672 ..= 67702:
    fallthrough
  case 67705 ..= 67742:
    fallthrough
  case 67751 ..= 67759:
    fallthrough
  case 67808 ..= 67826:
    fallthrough
  case 67828 ..= 67829:
    fallthrough
  case 67835 ..= 67867:
    fallthrough
  case 67872 ..= 67897:
    fallthrough
  case 67968 ..= 68023:
    fallthrough
  case 68028 ..= 68047:
    fallthrough
  case 68050 ..= 68096:
    fallthrough
  case 68112 ..= 68115:
    fallthrough
  case 68117 ..= 68119:
    fallthrough
  case 68121 ..= 68149:
    fallthrough
  case 68160 ..= 68168:
    fallthrough
  case 68192 ..= 68222:
    fallthrough
  case 68224 ..= 68255:
    fallthrough
  case 68288 ..= 68295:
    fallthrough
  case 68297 ..= 68324:
    fallthrough
  case 68331 ..= 68335:
    fallthrough
  case 68352 ..= 68405:
    fallthrough
  case 68416 ..= 68437:
    fallthrough
  case 68440 ..= 68466:
    fallthrough
  case 68472 ..= 68497:
    fallthrough
  case 68521 ..= 68527:
    fallthrough
  case 68608 ..= 68680:
    fallthrough
  case 68736 ..= 68786:
    fallthrough
  case 68800 ..= 68850:
    fallthrough
  case 68858 ..= 68899:
    fallthrough
  case 68912 ..= 68921:
    fallthrough
  case 69216 ..= 69246:
    fallthrough
  case 69248 ..= 69289:
    fallthrough
  case 69296 ..= 69297:
    fallthrough
  case 69376 ..= 69415:
    fallthrough
  case 69424 ..= 69445:
    fallthrough
  case 69457 ..= 69460:
    fallthrough
  case 69552 ..= 69579:
    fallthrough
  case 69600 ..= 69622:
    fallthrough
  case 69635 ..= 69687:
    fallthrough
  case 69714 ..= 69743:
    fallthrough
  case 69763 ..= 69807:
    fallthrough
  case 69840 ..= 69864:
    fallthrough
  case 69872 ..= 69881:
    fallthrough
  case 69891 ..= 69926:
    fallthrough
  case 69942 ..= 69951:
    fallthrough
  case 69956:
    fallthrough
  case 69959:
    fallthrough
  case 69968 ..= 70002:
    fallthrough
  case 70006:
    fallthrough
  case 70019 ..= 70066:
    fallthrough
  case 70081 ..= 70084:
    fallthrough
  case 70096 ..= 70106:
    fallthrough
  case 70108:
    fallthrough
  case 70113 ..= 70132:
    fallthrough
  case 70144 ..= 70161:
    fallthrough
  case 70163 ..= 70187:
    fallthrough
  case 70272 ..= 70278:
    fallthrough
  case 70280:
    fallthrough
  case 70282 ..= 70285:
    fallthrough
  case 70287 ..= 70301:
    fallthrough
  case 70303 ..= 70312:
    fallthrough
  case 70320 ..= 70366:
    fallthrough
  case 70384 ..= 70393:
    fallthrough
  case 70405 ..= 70412:
    fallthrough
  case 70415 ..= 70416:
    fallthrough
  case 70419 ..= 70440:
    fallthrough
  case 70442 ..= 70448:
    fallthrough
  case 70450 ..= 70451:
    fallthrough
  case 70453 ..= 70457:
    fallthrough
  case 70461:
    fallthrough
  case 70480:
    fallthrough
  case 70493 ..= 70497:
    fallthrough
  case 70656 ..= 70708:
    fallthrough
  case 70727 ..= 70730:
    fallthrough
  case 70736 ..= 70745:
    fallthrough
  case 70751 ..= 70753:
    fallthrough
  case 70784 ..= 70831:
    fallthrough
  case 70852 ..= 70853:
    fallthrough
  case 70855:
    fallthrough
  case 70864 ..= 70873:
    fallthrough
  case 71040 ..= 71086:
    fallthrough
  case 71128 ..= 71131:
    fallthrough
  case 71168 ..= 71215:
    fallthrough
  case 71236:
    fallthrough
  case 71248 ..= 71257:
    fallthrough
  case 71296 ..= 71338:
    fallthrough
  case 71352:
    fallthrough
  case 71360 ..= 71369:
    fallthrough
  case 71424 ..= 71450:
    fallthrough
  case 71472 ..= 71483:
    fallthrough
  case 71680 ..= 71723:
    fallthrough
  case 71840 ..= 71922:
    fallthrough
  case 71935 ..= 71942:
    fallthrough
  case 71945:
    fallthrough
  case 71948 ..= 71955:
    fallthrough
  case 71957 ..= 71958:
    fallthrough
  case 71960 ..= 71983:
    fallthrough
  case 71999:
    fallthrough
  case 72001:
    fallthrough
  case 72016 ..= 72025:
    fallthrough
  case 72096 ..= 72103:
    fallthrough
  case 72106 ..= 72144:
    fallthrough
  case 72161:
    fallthrough
  case 72163:
    fallthrough
  case 72192:
    fallthrough
  case 72203 ..= 72242:
    fallthrough
  case 72250:
    fallthrough
  case 72272:
    fallthrough
  case 72284 ..= 72329:
    fallthrough
  case 72349:
    fallthrough
  case 72384 ..= 72440:
    fallthrough
  case 72704 ..= 72712:
    fallthrough
  case 72714 ..= 72750:
    fallthrough
  case 72768:
    fallthrough
  case 72784 ..= 72812:
    fallthrough
  case 72818 ..= 72847:
    fallthrough
  case 72960 ..= 72966:
    fallthrough
  case 72968 ..= 72969:
    fallthrough
  case 72971 ..= 73008:
    fallthrough
  case 73030:
    fallthrough
  case 73040 ..= 73049:
    fallthrough
  case 73056 ..= 73061:
    fallthrough
  case 73063 ..= 73064:
    fallthrough
  case 73066 ..= 73097:
    fallthrough
  case 73112:
    fallthrough
  case 73120 ..= 73129:
    fallthrough
  case 73440 ..= 73458:
    fallthrough
  case 73648:
    fallthrough
  case 73664 ..= 73684:
    fallthrough
  case 73728 ..= 74649:
    fallthrough
  case 74752 ..= 74862:
    fallthrough
  case 74880 ..= 75075:
    fallthrough
  case 77824 ..= 78894:
    fallthrough
  case 82944 ..= 83526:
    fallthrough
  case 92160 ..= 92728:
    fallthrough
  case 92736 ..= 92766:
    fallthrough
  case 92768 ..= 92777:
    fallthrough
  case 92880 ..= 92909:
    fallthrough
  case 92928 ..= 92975:
    fallthrough
  case 92992 ..= 92995:
    fallthrough
  case 93008 ..= 93017:
    fallthrough
  case 93019 ..= 93025:
    fallthrough
  case 93027 ..= 93047:
    fallthrough
  case 93053 ..= 93071:
    fallthrough
  case 93760 ..= 93846:
    fallthrough
  case 93952 ..= 94026:
    fallthrough
  case 94032:
    fallthrough
  case 94099 ..= 94111:
    fallthrough
  case 94176 ..= 94177:
    fallthrough
  case 94179:
    fallthrough
  case 94208 ..= 100343:
    fallthrough
  case 100352 ..= 101589:
    fallthrough
  case 101632 ..= 101640:
    fallthrough
  case 110592 ..= 110878:
    fallthrough
  case 110928 ..= 110930:
    fallthrough
  case 110948 ..= 110951:
    fallthrough
  case 110960 ..= 111355:
    fallthrough
  case 113664 ..= 113770:
    fallthrough
  case 113776 ..= 113788:
    fallthrough
  case 113792 ..= 113800:
    fallthrough
  case 113808 ..= 113817:
    fallthrough
  case 119520 ..= 119539:
    fallthrough
  case 119648 ..= 119672:
    fallthrough
  case 119808 ..= 119892:
    fallthrough
  case 119894 ..= 119964:
    fallthrough
  case 119966 ..= 119967:
    fallthrough
  case 119970:
    fallthrough
  case 119973 ..= 119974:
    fallthrough
  case 119977 ..= 119980:
    fallthrough
  case 119982 ..= 119993:
    fallthrough
  case 119995:
    fallthrough
  case 119997 ..= 120003:
    fallthrough
  case 120005 ..= 120069:
    fallthrough
  case 120071 ..= 120074:
    fallthrough
  case 120077 ..= 120084:
    fallthrough
  case 120086 ..= 120092:
    fallthrough
  case 120094 ..= 120121:
    fallthrough
  case 120123 ..= 120126:
    fallthrough
  case 120128 ..= 120132:
    fallthrough
  case 120134:
    fallthrough
  case 120138 ..= 120144:
    fallthrough
  case 120146 ..= 120485:
    fallthrough
  case 120488 ..= 120512:
    fallthrough
  case 120514 ..= 120538:
    fallthrough
  case 120540 ..= 120570:
    fallthrough
  case 120572 ..= 120596:
    fallthrough
  case 120598 ..= 120628:
    fallthrough
  case 120630 ..= 120654:
    fallthrough
  case 120656 ..= 120686:
    fallthrough
  case 120688 ..= 120712:
    fallthrough
  case 120714 ..= 120744:
    fallthrough
  case 120746 ..= 120770:
    fallthrough
  case 120772 ..= 120779:
    fallthrough
  case 120782 ..= 120831:
    fallthrough
  case 123136 ..= 123180:
    fallthrough
  case 123191 ..= 123197:
    fallthrough
  case 123200 ..= 123209:
    fallthrough
  case 123214:
    fallthrough
  case 123584 ..= 123627:
    fallthrough
  case 123632 ..= 123641:
    fallthrough
  case 124928 ..= 125124:
    fallthrough
  case 125127 ..= 125135:
    fallthrough
  case 125184 ..= 125251:
    fallthrough
  case 125259:
    fallthrough
  case 125264 ..= 125273:
    fallthrough
  case 126065 ..= 126123:
    fallthrough
  case 126125 ..= 126127:
    fallthrough
  case 126129 ..= 126132:
    fallthrough
  case 126209 ..= 126253:
    fallthrough
  case 126255 ..= 126269:
    fallthrough
  case 126464 ..= 126467:
    fallthrough
  case 126469 ..= 126495:
    fallthrough
  case 126497 ..= 126498:
    fallthrough
  case 126500:
    fallthrough
  case 126503:
    fallthrough
  case 126505 ..= 126514:
    fallthrough
  case 126516 ..= 126519:
    fallthrough
  case 126521:
    fallthrough
  case 126523:
    fallthrough
  case 126530:
    fallthrough
  case 126535:
    fallthrough
  case 126537:
    fallthrough
  case 126539:
    fallthrough
  case 126541 ..= 126543:
    fallthrough
  case 126545 ..= 126546:
    fallthrough
  case 126548:
    fallthrough
  case 126551:
    fallthrough
  case 126553:
    fallthrough
  case 126555:
    fallthrough
  case 126557:
    fallthrough
  case 126559:
    fallthrough
  case 126561 ..= 126562:
    fallthrough
  case 126564:
    fallthrough
  case 126567 ..= 126570:
    fallthrough
  case 126572 ..= 126578:
    fallthrough
  case 126580 ..= 126583:
    fallthrough
  case 126585 ..= 126588:
    fallthrough
  case 126590:
    fallthrough
  case 126592 ..= 126601:
    fallthrough
  case 126603 ..= 126619:
    fallthrough
  case 126625 ..= 126627:
    fallthrough
  case 126629 ..= 126633:
    fallthrough
  case 126635 ..= 126651:
    fallthrough
  case 127232 ..= 127244:
    fallthrough
  case 130032 ..= 130041:
    fallthrough
  case 131072 ..= 173789:
    fallthrough
  case 173824 ..= 177972:
    fallthrough
  case 177984 ..= 178205:
    fallthrough
  case 178208 ..= 183969:
    fallthrough
  case 183984 ..= 191456:
    fallthrough
  case 194560 ..= 195101:
    fallthrough
  case 196608 ..= 201546:
    return true
  }
  return false
}

isShorthandWord_ascii :: proc(rn: rune) -> bool {
  // matches word regex "\w" flag="ASCII"
  switch u32(rn) {
  case 48 ..= 57:
    fallthrough
  case 65 ..= 90:
    fallthrough
  case 95:
    fallthrough
  case 97 ..= 122:
    return true
  }
  return false
}

isShorthandDigit_utf8 :: proc(rn: rune) -> bool {
  // matches Digit regex "\d"
  // TODO optimize check - binary search speed up check
  switch u32(rn) {
  case 48 ..= 57:
    fallthrough
  case 1632 ..= 1641:
    fallthrough
  case 1776 ..= 1785:
    fallthrough
  case 1984 ..= 1993:
    fallthrough
  case 2406 ..= 2415:
    fallthrough
  case 2534 ..= 2543:
    fallthrough
  case 2662 ..= 2671:
    fallthrough
  case 2790 ..= 2799:
    fallthrough
  case 2918 ..= 2927:
    fallthrough
  case 3046 ..= 3055:
    fallthrough
  case 3174 ..= 3183:
    fallthrough
  case 3302 ..= 3311:
    fallthrough
  case 3430 ..= 3439:
    fallthrough
  case 3558 ..= 3567:
    fallthrough
  case 3664 ..= 3673:
    fallthrough
  case 3792 ..= 3801:
    fallthrough
  case 3872 ..= 3881:
    fallthrough
  case 4160 ..= 4169:
    fallthrough
  case 4240 ..= 4249:
    fallthrough
  case 6112 ..= 6121:
    fallthrough
  case 6160 ..= 6169:
    fallthrough
  case 6470 ..= 6479:
    fallthrough
  case 6608 ..= 6617:
    fallthrough
  case 6784 ..= 6793:
    fallthrough
  case 6800 ..= 6809:
    fallthrough
  case 6992 ..= 7001:
    fallthrough
  case 7088 ..= 7097:
    fallthrough
  case 7232 ..= 7241:
    fallthrough
  case 7248 ..= 7257:
    fallthrough
  case 42528 ..= 42537:
    fallthrough
  case 43216 ..= 43225:
    fallthrough
  case 43264 ..= 43273:
    fallthrough
  case 43472 ..= 43481:
    fallthrough
  case 43504 ..= 43513:
    fallthrough
  case 43600 ..= 43609:
    fallthrough
  case 44016 ..= 44025:
    fallthrough
  case 65296 ..= 65305:
    fallthrough
  case 66720 ..= 66729:
    fallthrough
  case 68912 ..= 68921:
    fallthrough
  case 69734 ..= 69743:
    fallthrough
  case 69872 ..= 69881:
    fallthrough
  case 69942 ..= 69951:
    fallthrough
  case 70096 ..= 70105:
    fallthrough
  case 70384 ..= 70393:
    fallthrough
  case 70736 ..= 70745:
    fallthrough
  case 70864 ..= 70873:
    fallthrough
  case 71248 ..= 71257:
    fallthrough
  case 71360 ..= 71369:
    fallthrough
  case 71472 ..= 71481:
    fallthrough
  case 71904 ..= 71913:
    fallthrough
  case 72016 ..= 72025:
    fallthrough
  case 72784 ..= 72793:
    fallthrough
  case 73040 ..= 73049:
    fallthrough
  case 73120 ..= 73129:
    fallthrough
  case 92768 ..= 92777:
    fallthrough
  case 93008 ..= 93017:
    fallthrough
  case 120782 ..= 120831:
    fallthrough
  case 123200 ..= 123209:
    fallthrough
  case 123632 ..= 123641:
    fallthrough
  case 125264 ..= 125273:
    fallthrough
  case 130032 ..= 130041:
    return true
  }
  return false
}

isShorthandDigit_ascii :: proc(rn: rune) -> bool {
  // matches Digit regex "\d" flag="ASCII"
  switch u32(rn) {
  case 48 ..= 57:
    return true
  }
  return false
}

/////////////////////////////////

isShorthandWord :: proc(rn: rune, ascii: bool = false) -> bool {
  return ascii ? isShorthandWord_ascii(rn) : isShorthandWord_utf8(rn)
}

isShorthandWhitespace :: proc(rn: rune, ascii: bool = false) -> bool {
  return ascii ? isShorthandWhitespace_ascii(rn) : isShorthandWhitespace_utf8(rn)
}

isShorthandDigit :: proc(rn: rune, ascii: bool = false) -> bool {
  return ascii ? isShorthandDigit_ascii(rn) : isShorthandDigit_utf8(rn)
}

matchesCharacterClass :: proc(
  curr_rune: rune,
  sh_class: ShortHandClass,
  prev_rune: rune = {},
  ascii: bool = false,
  at_beginning: bool = false,
  at_end: bool = false,
) -> bool {
  switch sh_class {
  case .Flag_W:
    return isShorthandWord(rn = curr_rune, ascii = ascii)
  case .Flag_D:
    return isShorthandDigit(rn = curr_rune, ascii = ascii)
  case .Flag_S:
    return isShorthandWhitespace(rn = curr_rune, ascii = ascii)
  case .Flag_Dot:
    return curr_rune != '\n'
  case .Flag_B:
    if at_beginning || at_end {
      return true
    }
    // not at beginning or end
    token_is_word := isShorthandWord(rn = curr_rune, ascii = ascii)
    prev_rune_is_word := isShorthandWord(rn = prev_rune, ascii = ascii)
    return token_is_word != prev_rune_is_word
  }
  return false
}
