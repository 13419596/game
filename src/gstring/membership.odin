package gstring

// Generated from:
/*```python
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
  out = [f'{function_name} :: proc(token:rune) -> bool {{', ]
  if doc_comment:
    out.append(indent*1 + '// ' + doc_comment)
  ##
  out.append(indent*1 + 'switch u32(token) {')
  for lb, rb in breakpoints:
    if lb!=rb:
      out.append(indent*2 + f'case {lb}..={rb}: return true')
    else:
      out.append(indent*2 + f'case {lb}: return true')
    ##
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
patterns = [('whitespace',r'\s'),('word',r'\w'),('decimal', r'\d'),]

odin_funcs = []
for name, pattern in patterns:
  matches = [ch for ch in all_utf8 if re.match(pattern,ch)]
  # print(f'Pattern {name} {pattern!r} -- matches:{len(matches)} inverse:{len(all_utf8)-len(matches)}')
  utf8_points = [ord(ch) for ch in matches]
  utf8_bps = getBreakPointsInSequences(utf8_points)
  code = writeOdinBreakpointChecks(utf8_bps,f'is_utf8_{name}', doc_comment=f'matches {name} regex "{pattern}"')
  odin_funcs.append(code)
  ascii_points = [ord(ch) for ch in matches if ch.isascii()]
  ascii_bps = getBreakPointsInSequences(ascii_points)
  code = writeOdinBreakpointChecks(ascii_bps,f'is_ascii_{name}', doc_comment=f'matches {name} regex "{pattern}" flag="ASCII"')
  odin_funcs.append(code)
##

print('\n\n'.join(odin_funcs))
```*/

is_utf8_whitespace :: proc(token: rune) -> bool {
  // matches whitespace regex "\s"
  switch u32(token) {
  case 9 ..= 13:
    return true
  case 28 ..= 32:
    return true
  case 133:
    return true
  case 160:
    return true
  case 5760:
    return true
  case 8192 ..= 8202:
    return true
  case 8232 ..= 8233:
    return true
  case 8239:
    return true
  case 8287:
    return true
  case 12288:
    return true
  }
  return false
}

is_ascii_whitespace :: proc(token: rune) -> bool {
  // matches whitespace regex "\s" flag="ASCII"
  switch u32(token) {
  case 9 ..= 13:
    return true
  case 28 ..= 32:
    return true
  }
  return false
}

is_utf8_word :: proc(token: rune) -> bool {
  // matches word regex "\w"
  switch u32(token) {
  case 48 ..= 57:
    return true
  case 65 ..= 90:
    return true
  case 95:
    return true
  case 97 ..= 122:
    return true
  case 170:
    return true
  case 178 ..= 179:
    return true
  case 181:
    return true
  case 185 ..= 186:
    return true
  case 188 ..= 190:
    return true
  case 192 ..= 214:
    return true
  case 216 ..= 246:
    return true
  case 248 ..= 705:
    return true
  case 710 ..= 721:
    return true
  case 736 ..= 740:
    return true
  case 748:
    return true
  case 750:
    return true
  case 880 ..= 884:
    return true
  case 886 ..= 887:
    return true
  case 890 ..= 893:
    return true
  case 895:
    return true
  case 902:
    return true
  case 904 ..= 906:
    return true
  case 908:
    return true
  case 910 ..= 929:
    return true
  case 931 ..= 1013:
    return true
  case 1015 ..= 1153:
    return true
  case 1162 ..= 1327:
    return true
  case 1329 ..= 1366:
    return true
  case 1369:
    return true
  case 1376 ..= 1416:
    return true
  case 1488 ..= 1514:
    return true
  case 1519 ..= 1522:
    return true
  case 1568 ..= 1610:
    return true
  case 1632 ..= 1641:
    return true
  case 1646 ..= 1647:
    return true
  case 1649 ..= 1747:
    return true
  case 1749:
    return true
  case 1765 ..= 1766:
    return true
  case 1774 ..= 1788:
    return true
  case 1791:
    return true
  case 1808:
    return true
  case 1810 ..= 1839:
    return true
  case 1869 ..= 1957:
    return true
  case 1969:
    return true
  case 1984 ..= 2026:
    return true
  case 2036 ..= 2037:
    return true
  case 2042:
    return true
  case 2048 ..= 2069:
    return true
  case 2074:
    return true
  case 2084:
    return true
  case 2088:
    return true
  case 2112 ..= 2136:
    return true
  case 2144 ..= 2154:
    return true
  case 2208 ..= 2228:
    return true
  case 2230 ..= 2247:
    return true
  case 2308 ..= 2361:
    return true
  case 2365:
    return true
  case 2384:
    return true
  case 2392 ..= 2401:
    return true
  case 2406 ..= 2415:
    return true
  case 2417 ..= 2432:
    return true
  case 2437 ..= 2444:
    return true
  case 2447 ..= 2448:
    return true
  case 2451 ..= 2472:
    return true
  case 2474 ..= 2480:
    return true
  case 2482:
    return true
  case 2486 ..= 2489:
    return true
  case 2493:
    return true
  case 2510:
    return true
  case 2524 ..= 2525:
    return true
  case 2527 ..= 2529:
    return true
  case 2534 ..= 2545:
    return true
  case 2548 ..= 2553:
    return true
  case 2556:
    return true
  case 2565 ..= 2570:
    return true
  case 2575 ..= 2576:
    return true
  case 2579 ..= 2600:
    return true
  case 2602 ..= 2608:
    return true
  case 2610 ..= 2611:
    return true
  case 2613 ..= 2614:
    return true
  case 2616 ..= 2617:
    return true
  case 2649 ..= 2652:
    return true
  case 2654:
    return true
  case 2662 ..= 2671:
    return true
  case 2674 ..= 2676:
    return true
  case 2693 ..= 2701:
    return true
  case 2703 ..= 2705:
    return true
  case 2707 ..= 2728:
    return true
  case 2730 ..= 2736:
    return true
  case 2738 ..= 2739:
    return true
  case 2741 ..= 2745:
    return true
  case 2749:
    return true
  case 2768:
    return true
  case 2784 ..= 2785:
    return true
  case 2790 ..= 2799:
    return true
  case 2809:
    return true
  case 2821 ..= 2828:
    return true
  case 2831 ..= 2832:
    return true
  case 2835 ..= 2856:
    return true
  case 2858 ..= 2864:
    return true
  case 2866 ..= 2867:
    return true
  case 2869 ..= 2873:
    return true
  case 2877:
    return true
  case 2908 ..= 2909:
    return true
  case 2911 ..= 2913:
    return true
  case 2918 ..= 2927:
    return true
  case 2929 ..= 2935:
    return true
  case 2947:
    return true
  case 2949 ..= 2954:
    return true
  case 2958 ..= 2960:
    return true
  case 2962 ..= 2965:
    return true
  case 2969 ..= 2970:
    return true
  case 2972:
    return true
  case 2974 ..= 2975:
    return true
  case 2979 ..= 2980:
    return true
  case 2984 ..= 2986:
    return true
  case 2990 ..= 3001:
    return true
  case 3024:
    return true
  case 3046 ..= 3058:
    return true
  case 3077 ..= 3084:
    return true
  case 3086 ..= 3088:
    return true
  case 3090 ..= 3112:
    return true
  case 3114 ..= 3129:
    return true
  case 3133:
    return true
  case 3160 ..= 3162:
    return true
  case 3168 ..= 3169:
    return true
  case 3174 ..= 3183:
    return true
  case 3192 ..= 3198:
    return true
  case 3200:
    return true
  case 3205 ..= 3212:
    return true
  case 3214 ..= 3216:
    return true
  case 3218 ..= 3240:
    return true
  case 3242 ..= 3251:
    return true
  case 3253 ..= 3257:
    return true
  case 3261:
    return true
  case 3294:
    return true
  case 3296 ..= 3297:
    return true
  case 3302 ..= 3311:
    return true
  case 3313 ..= 3314:
    return true
  case 3332 ..= 3340:
    return true
  case 3342 ..= 3344:
    return true
  case 3346 ..= 3386:
    return true
  case 3389:
    return true
  case 3406:
    return true
  case 3412 ..= 3414:
    return true
  case 3416 ..= 3425:
    return true
  case 3430 ..= 3448:
    return true
  case 3450 ..= 3455:
    return true
  case 3461 ..= 3478:
    return true
  case 3482 ..= 3505:
    return true
  case 3507 ..= 3515:
    return true
  case 3517:
    return true
  case 3520 ..= 3526:
    return true
  case 3558 ..= 3567:
    return true
  case 3585 ..= 3632:
    return true
  case 3634 ..= 3635:
    return true
  case 3648 ..= 3654:
    return true
  case 3664 ..= 3673:
    return true
  case 3713 ..= 3714:
    return true
  case 3716:
    return true
  case 3718 ..= 3722:
    return true
  case 3724 ..= 3747:
    return true
  case 3749:
    return true
  case 3751 ..= 3760:
    return true
  case 3762 ..= 3763:
    return true
  case 3773:
    return true
  case 3776 ..= 3780:
    return true
  case 3782:
    return true
  case 3792 ..= 3801:
    return true
  case 3804 ..= 3807:
    return true
  case 3840:
    return true
  case 3872 ..= 3891:
    return true
  case 3904 ..= 3911:
    return true
  case 3913 ..= 3948:
    return true
  case 3976 ..= 3980:
    return true
  case 4096 ..= 4138:
    return true
  case 4159 ..= 4169:
    return true
  case 4176 ..= 4181:
    return true
  case 4186 ..= 4189:
    return true
  case 4193:
    return true
  case 4197 ..= 4198:
    return true
  case 4206 ..= 4208:
    return true
  case 4213 ..= 4225:
    return true
  case 4238:
    return true
  case 4240 ..= 4249:
    return true
  case 4256 ..= 4293:
    return true
  case 4295:
    return true
  case 4301:
    return true
  case 4304 ..= 4346:
    return true
  case 4348 ..= 4680:
    return true
  case 4682 ..= 4685:
    return true
  case 4688 ..= 4694:
    return true
  case 4696:
    return true
  case 4698 ..= 4701:
    return true
  case 4704 ..= 4744:
    return true
  case 4746 ..= 4749:
    return true
  case 4752 ..= 4784:
    return true
  case 4786 ..= 4789:
    return true
  case 4792 ..= 4798:
    return true
  case 4800:
    return true
  case 4802 ..= 4805:
    return true
  case 4808 ..= 4822:
    return true
  case 4824 ..= 4880:
    return true
  case 4882 ..= 4885:
    return true
  case 4888 ..= 4954:
    return true
  case 4969 ..= 4988:
    return true
  case 4992 ..= 5007:
    return true
  case 5024 ..= 5109:
    return true
  case 5112 ..= 5117:
    return true
  case 5121 ..= 5740:
    return true
  case 5743 ..= 5759:
    return true
  case 5761 ..= 5786:
    return true
  case 5792 ..= 5866:
    return true
  case 5870 ..= 5880:
    return true
  case 5888 ..= 5900:
    return true
  case 5902 ..= 5905:
    return true
  case 5920 ..= 5937:
    return true
  case 5952 ..= 5969:
    return true
  case 5984 ..= 5996:
    return true
  case 5998 ..= 6000:
    return true
  case 6016 ..= 6067:
    return true
  case 6103:
    return true
  case 6108:
    return true
  case 6112 ..= 6121:
    return true
  case 6128 ..= 6137:
    return true
  case 6160 ..= 6169:
    return true
  case 6176 ..= 6264:
    return true
  case 6272 ..= 6276:
    return true
  case 6279 ..= 6312:
    return true
  case 6314:
    return true
  case 6320 ..= 6389:
    return true
  case 6400 ..= 6430:
    return true
  case 6470 ..= 6509:
    return true
  case 6512 ..= 6516:
    return true
  case 6528 ..= 6571:
    return true
  case 6576 ..= 6601:
    return true
  case 6608 ..= 6618:
    return true
  case 6656 ..= 6678:
    return true
  case 6688 ..= 6740:
    return true
  case 6784 ..= 6793:
    return true
  case 6800 ..= 6809:
    return true
  case 6823:
    return true
  case 6917 ..= 6963:
    return true
  case 6981 ..= 6987:
    return true
  case 6992 ..= 7001:
    return true
  case 7043 ..= 7072:
    return true
  case 7086 ..= 7141:
    return true
  case 7168 ..= 7203:
    return true
  case 7232 ..= 7241:
    return true
  case 7245 ..= 7293:
    return true
  case 7296 ..= 7304:
    return true
  case 7312 ..= 7354:
    return true
  case 7357 ..= 7359:
    return true
  case 7401 ..= 7404:
    return true
  case 7406 ..= 7411:
    return true
  case 7413 ..= 7414:
    return true
  case 7418:
    return true
  case 7424 ..= 7615:
    return true
  case 7680 ..= 7957:
    return true
  case 7960 ..= 7965:
    return true
  case 7968 ..= 8005:
    return true
  case 8008 ..= 8013:
    return true
  case 8016 ..= 8023:
    return true
  case 8025:
    return true
  case 8027:
    return true
  case 8029:
    return true
  case 8031 ..= 8061:
    return true
  case 8064 ..= 8116:
    return true
  case 8118 ..= 8124:
    return true
  case 8126:
    return true
  case 8130 ..= 8132:
    return true
  case 8134 ..= 8140:
    return true
  case 8144 ..= 8147:
    return true
  case 8150 ..= 8155:
    return true
  case 8160 ..= 8172:
    return true
  case 8178 ..= 8180:
    return true
  case 8182 ..= 8188:
    return true
  case 8304 ..= 8305:
    return true
  case 8308 ..= 8313:
    return true
  case 8319 ..= 8329:
    return true
  case 8336 ..= 8348:
    return true
  case 8450:
    return true
  case 8455:
    return true
  case 8458 ..= 8467:
    return true
  case 8469:
    return true
  case 8473 ..= 8477:
    return true
  case 8484:
    return true
  case 8486:
    return true
  case 8488:
    return true
  case 8490 ..= 8493:
    return true
  case 8495 ..= 8505:
    return true
  case 8508 ..= 8511:
    return true
  case 8517 ..= 8521:
    return true
  case 8526:
    return true
  case 8528 ..= 8585:
    return true
  case 9312 ..= 9371:
    return true
  case 9450 ..= 9471:
    return true
  case 10102 ..= 10131:
    return true
  case 11264 ..= 11310:
    return true
  case 11312 ..= 11358:
    return true
  case 11360 ..= 11492:
    return true
  case 11499 ..= 11502:
    return true
  case 11506 ..= 11507:
    return true
  case 11517:
    return true
  case 11520 ..= 11557:
    return true
  case 11559:
    return true
  case 11565:
    return true
  case 11568 ..= 11623:
    return true
  case 11631:
    return true
  case 11648 ..= 11670:
    return true
  case 11680 ..= 11686:
    return true
  case 11688 ..= 11694:
    return true
  case 11696 ..= 11702:
    return true
  case 11704 ..= 11710:
    return true
  case 11712 ..= 11718:
    return true
  case 11720 ..= 11726:
    return true
  case 11728 ..= 11734:
    return true
  case 11736 ..= 11742:
    return true
  case 11823:
    return true
  case 12293 ..= 12295:
    return true
  case 12321 ..= 12329:
    return true
  case 12337 ..= 12341:
    return true
  case 12344 ..= 12348:
    return true
  case 12353 ..= 12438:
    return true
  case 12445 ..= 12447:
    return true
  case 12449 ..= 12538:
    return true
  case 12540 ..= 12543:
    return true
  case 12549 ..= 12591:
    return true
  case 12593 ..= 12686:
    return true
  case 12690 ..= 12693:
    return true
  case 12704 ..= 12735:
    return true
  case 12784 ..= 12799:
    return true
  case 12832 ..= 12841:
    return true
  case 12872 ..= 12879:
    return true
  case 12881 ..= 12895:
    return true
  case 12928 ..= 12937:
    return true
  case 12977 ..= 12991:
    return true
  case 13312 ..= 19903:
    return true
  case 19968 ..= 40956:
    return true
  case 40960 ..= 42124:
    return true
  case 42192 ..= 42237:
    return true
  case 42240 ..= 42508:
    return true
  case 42512 ..= 42539:
    return true
  case 42560 ..= 42606:
    return true
  case 42623 ..= 42653:
    return true
  case 42656 ..= 42735:
    return true
  case 42775 ..= 42783:
    return true
  case 42786 ..= 42888:
    return true
  case 42891 ..= 42943:
    return true
  case 42946 ..= 42954:
    return true
  case 42997 ..= 43009:
    return true
  case 43011 ..= 43013:
    return true
  case 43015 ..= 43018:
    return true
  case 43020 ..= 43042:
    return true
  case 43056 ..= 43061:
    return true
  case 43072 ..= 43123:
    return true
  case 43138 ..= 43187:
    return true
  case 43216 ..= 43225:
    return true
  case 43250 ..= 43255:
    return true
  case 43259:
    return true
  case 43261 ..= 43262:
    return true
  case 43264 ..= 43301:
    return true
  case 43312 ..= 43334:
    return true
  case 43360 ..= 43388:
    return true
  case 43396 ..= 43442:
    return true
  case 43471 ..= 43481:
    return true
  case 43488 ..= 43492:
    return true
  case 43494 ..= 43518:
    return true
  case 43520 ..= 43560:
    return true
  case 43584 ..= 43586:
    return true
  case 43588 ..= 43595:
    return true
  case 43600 ..= 43609:
    return true
  case 43616 ..= 43638:
    return true
  case 43642:
    return true
  case 43646 ..= 43695:
    return true
  case 43697:
    return true
  case 43701 ..= 43702:
    return true
  case 43705 ..= 43709:
    return true
  case 43712:
    return true
  case 43714:
    return true
  case 43739 ..= 43741:
    return true
  case 43744 ..= 43754:
    return true
  case 43762 ..= 43764:
    return true
  case 43777 ..= 43782:
    return true
  case 43785 ..= 43790:
    return true
  case 43793 ..= 43798:
    return true
  case 43808 ..= 43814:
    return true
  case 43816 ..= 43822:
    return true
  case 43824 ..= 43866:
    return true
  case 43868 ..= 43881:
    return true
  case 43888 ..= 44002:
    return true
  case 44016 ..= 44025:
    return true
  case 44032 ..= 55203:
    return true
  case 55216 ..= 55238:
    return true
  case 55243 ..= 55291:
    return true
  case 63744 ..= 64109:
    return true
  case 64112 ..= 64217:
    return true
  case 64256 ..= 64262:
    return true
  case 64275 ..= 64279:
    return true
  case 64285:
    return true
  case 64287 ..= 64296:
    return true
  case 64298 ..= 64310:
    return true
  case 64312 ..= 64316:
    return true
  case 64318:
    return true
  case 64320 ..= 64321:
    return true
  case 64323 ..= 64324:
    return true
  case 64326 ..= 64433:
    return true
  case 64467 ..= 64829:
    return true
  case 64848 ..= 64911:
    return true
  case 64914 ..= 64967:
    return true
  case 65008 ..= 65019:
    return true
  case 65136 ..= 65140:
    return true
  case 65142 ..= 65276:
    return true
  case 65296 ..= 65305:
    return true
  case 65313 ..= 65338:
    return true
  case 65345 ..= 65370:
    return true
  case 65382 ..= 65470:
    return true
  case 65474 ..= 65479:
    return true
  case 65482 ..= 65487:
    return true
  case 65490 ..= 65495:
    return true
  case 65498 ..= 65500:
    return true
  case 65536 ..= 65547:
    return true
  case 65549 ..= 65574:
    return true
  case 65576 ..= 65594:
    return true
  case 65596 ..= 65597:
    return true
  case 65599 ..= 65613:
    return true
  case 65616 ..= 65629:
    return true
  case 65664 ..= 65786:
    return true
  case 65799 ..= 65843:
    return true
  case 65856 ..= 65912:
    return true
  case 65930 ..= 65931:
    return true
  case 66176 ..= 66204:
    return true
  case 66208 ..= 66256:
    return true
  case 66273 ..= 66299:
    return true
  case 66304 ..= 66339:
    return true
  case 66349 ..= 66378:
    return true
  case 66384 ..= 66421:
    return true
  case 66432 ..= 66461:
    return true
  case 66464 ..= 66499:
    return true
  case 66504 ..= 66511:
    return true
  case 66513 ..= 66517:
    return true
  case 66560 ..= 66717:
    return true
  case 66720 ..= 66729:
    return true
  case 66736 ..= 66771:
    return true
  case 66776 ..= 66811:
    return true
  case 66816 ..= 66855:
    return true
  case 66864 ..= 66915:
    return true
  case 67072 ..= 67382:
    return true
  case 67392 ..= 67413:
    return true
  case 67424 ..= 67431:
    return true
  case 67584 ..= 67589:
    return true
  case 67592:
    return true
  case 67594 ..= 67637:
    return true
  case 67639 ..= 67640:
    return true
  case 67644:
    return true
  case 67647 ..= 67669:
    return true
  case 67672 ..= 67702:
    return true
  case 67705 ..= 67742:
    return true
  case 67751 ..= 67759:
    return true
  case 67808 ..= 67826:
    return true
  case 67828 ..= 67829:
    return true
  case 67835 ..= 67867:
    return true
  case 67872 ..= 67897:
    return true
  case 67968 ..= 68023:
    return true
  case 68028 ..= 68047:
    return true
  case 68050 ..= 68096:
    return true
  case 68112 ..= 68115:
    return true
  case 68117 ..= 68119:
    return true
  case 68121 ..= 68149:
    return true
  case 68160 ..= 68168:
    return true
  case 68192 ..= 68222:
    return true
  case 68224 ..= 68255:
    return true
  case 68288 ..= 68295:
    return true
  case 68297 ..= 68324:
    return true
  case 68331 ..= 68335:
    return true
  case 68352 ..= 68405:
    return true
  case 68416 ..= 68437:
    return true
  case 68440 ..= 68466:
    return true
  case 68472 ..= 68497:
    return true
  case 68521 ..= 68527:
    return true
  case 68608 ..= 68680:
    return true
  case 68736 ..= 68786:
    return true
  case 68800 ..= 68850:
    return true
  case 68858 ..= 68899:
    return true
  case 68912 ..= 68921:
    return true
  case 69216 ..= 69246:
    return true
  case 69248 ..= 69289:
    return true
  case 69296 ..= 69297:
    return true
  case 69376 ..= 69415:
    return true
  case 69424 ..= 69445:
    return true
  case 69457 ..= 69460:
    return true
  case 69552 ..= 69579:
    return true
  case 69600 ..= 69622:
    return true
  case 69635 ..= 69687:
    return true
  case 69714 ..= 69743:
    return true
  case 69763 ..= 69807:
    return true
  case 69840 ..= 69864:
    return true
  case 69872 ..= 69881:
    return true
  case 69891 ..= 69926:
    return true
  case 69942 ..= 69951:
    return true
  case 69956:
    return true
  case 69959:
    return true
  case 69968 ..= 70002:
    return true
  case 70006:
    return true
  case 70019 ..= 70066:
    return true
  case 70081 ..= 70084:
    return true
  case 70096 ..= 70106:
    return true
  case 70108:
    return true
  case 70113 ..= 70132:
    return true
  case 70144 ..= 70161:
    return true
  case 70163 ..= 70187:
    return true
  case 70272 ..= 70278:
    return true
  case 70280:
    return true
  case 70282 ..= 70285:
    return true
  case 70287 ..= 70301:
    return true
  case 70303 ..= 70312:
    return true
  case 70320 ..= 70366:
    return true
  case 70384 ..= 70393:
    return true
  case 70405 ..= 70412:
    return true
  case 70415 ..= 70416:
    return true
  case 70419 ..= 70440:
    return true
  case 70442 ..= 70448:
    return true
  case 70450 ..= 70451:
    return true
  case 70453 ..= 70457:
    return true
  case 70461:
    return true
  case 70480:
    return true
  case 70493 ..= 70497:
    return true
  case 70656 ..= 70708:
    return true
  case 70727 ..= 70730:
    return true
  case 70736 ..= 70745:
    return true
  case 70751 ..= 70753:
    return true
  case 70784 ..= 70831:
    return true
  case 70852 ..= 70853:
    return true
  case 70855:
    return true
  case 70864 ..= 70873:
    return true
  case 71040 ..= 71086:
    return true
  case 71128 ..= 71131:
    return true
  case 71168 ..= 71215:
    return true
  case 71236:
    return true
  case 71248 ..= 71257:
    return true
  case 71296 ..= 71338:
    return true
  case 71352:
    return true
  case 71360 ..= 71369:
    return true
  case 71424 ..= 71450:
    return true
  case 71472 ..= 71483:
    return true
  case 71680 ..= 71723:
    return true
  case 71840 ..= 71922:
    return true
  case 71935 ..= 71942:
    return true
  case 71945:
    return true
  case 71948 ..= 71955:
    return true
  case 71957 ..= 71958:
    return true
  case 71960 ..= 71983:
    return true
  case 71999:
    return true
  case 72001:
    return true
  case 72016 ..= 72025:
    return true
  case 72096 ..= 72103:
    return true
  case 72106 ..= 72144:
    return true
  case 72161:
    return true
  case 72163:
    return true
  case 72192:
    return true
  case 72203 ..= 72242:
    return true
  case 72250:
    return true
  case 72272:
    return true
  case 72284 ..= 72329:
    return true
  case 72349:
    return true
  case 72384 ..= 72440:
    return true
  case 72704 ..= 72712:
    return true
  case 72714 ..= 72750:
    return true
  case 72768:
    return true
  case 72784 ..= 72812:
    return true
  case 72818 ..= 72847:
    return true
  case 72960 ..= 72966:
    return true
  case 72968 ..= 72969:
    return true
  case 72971 ..= 73008:
    return true
  case 73030:
    return true
  case 73040 ..= 73049:
    return true
  case 73056 ..= 73061:
    return true
  case 73063 ..= 73064:
    return true
  case 73066 ..= 73097:
    return true
  case 73112:
    return true
  case 73120 ..= 73129:
    return true
  case 73440 ..= 73458:
    return true
  case 73648:
    return true
  case 73664 ..= 73684:
    return true
  case 73728 ..= 74649:
    return true
  case 74752 ..= 74862:
    return true
  case 74880 ..= 75075:
    return true
  case 77824 ..= 78894:
    return true
  case 82944 ..= 83526:
    return true
  case 92160 ..= 92728:
    return true
  case 92736 ..= 92766:
    return true
  case 92768 ..= 92777:
    return true
  case 92880 ..= 92909:
    return true
  case 92928 ..= 92975:
    return true
  case 92992 ..= 92995:
    return true
  case 93008 ..= 93017:
    return true
  case 93019 ..= 93025:
    return true
  case 93027 ..= 93047:
    return true
  case 93053 ..= 93071:
    return true
  case 93760 ..= 93846:
    return true
  case 93952 ..= 94026:
    return true
  case 94032:
    return true
  case 94099 ..= 94111:
    return true
  case 94176 ..= 94177:
    return true
  case 94179:
    return true
  case 94208 ..= 100343:
    return true
  case 100352 ..= 101589:
    return true
  case 101632 ..= 101640:
    return true
  case 110592 ..= 110878:
    return true
  case 110928 ..= 110930:
    return true
  case 110948 ..= 110951:
    return true
  case 110960 ..= 111355:
    return true
  case 113664 ..= 113770:
    return true
  case 113776 ..= 113788:
    return true
  case 113792 ..= 113800:
    return true
  case 113808 ..= 113817:
    return true
  case 119520 ..= 119539:
    return true
  case 119648 ..= 119672:
    return true
  case 119808 ..= 119892:
    return true
  case 119894 ..= 119964:
    return true
  case 119966 ..= 119967:
    return true
  case 119970:
    return true
  case 119973 ..= 119974:
    return true
  case 119977 ..= 119980:
    return true
  case 119982 ..= 119993:
    return true
  case 119995:
    return true
  case 119997 ..= 120003:
    return true
  case 120005 ..= 120069:
    return true
  case 120071 ..= 120074:
    return true
  case 120077 ..= 120084:
    return true
  case 120086 ..= 120092:
    return true
  case 120094 ..= 120121:
    return true
  case 120123 ..= 120126:
    return true
  case 120128 ..= 120132:
    return true
  case 120134:
    return true
  case 120138 ..= 120144:
    return true
  case 120146 ..= 120485:
    return true
  case 120488 ..= 120512:
    return true
  case 120514 ..= 120538:
    return true
  case 120540 ..= 120570:
    return true
  case 120572 ..= 120596:
    return true
  case 120598 ..= 120628:
    return true
  case 120630 ..= 120654:
    return true
  case 120656 ..= 120686:
    return true
  case 120688 ..= 120712:
    return true
  case 120714 ..= 120744:
    return true
  case 120746 ..= 120770:
    return true
  case 120772 ..= 120779:
    return true
  case 120782 ..= 120831:
    return true
  case 123136 ..= 123180:
    return true
  case 123191 ..= 123197:
    return true
  case 123200 ..= 123209:
    return true
  case 123214:
    return true
  case 123584 ..= 123627:
    return true
  case 123632 ..= 123641:
    return true
  case 124928 ..= 125124:
    return true
  case 125127 ..= 125135:
    return true
  case 125184 ..= 125251:
    return true
  case 125259:
    return true
  case 125264 ..= 125273:
    return true
  case 126065 ..= 126123:
    return true
  case 126125 ..= 126127:
    return true
  case 126129 ..= 126132:
    return true
  case 126209 ..= 126253:
    return true
  case 126255 ..= 126269:
    return true
  case 126464 ..= 126467:
    return true
  case 126469 ..= 126495:
    return true
  case 126497 ..= 126498:
    return true
  case 126500:
    return true
  case 126503:
    return true
  case 126505 ..= 126514:
    return true
  case 126516 ..= 126519:
    return true
  case 126521:
    return true
  case 126523:
    return true
  case 126530:
    return true
  case 126535:
    return true
  case 126537:
    return true
  case 126539:
    return true
  case 126541 ..= 126543:
    return true
  case 126545 ..= 126546:
    return true
  case 126548:
    return true
  case 126551:
    return true
  case 126553:
    return true
  case 126555:
    return true
  case 126557:
    return true
  case 126559:
    return true
  case 126561 ..= 126562:
    return true
  case 126564:
    return true
  case 126567 ..= 126570:
    return true
  case 126572 ..= 126578:
    return true
  case 126580 ..= 126583:
    return true
  case 126585 ..= 126588:
    return true
  case 126590:
    return true
  case 126592 ..= 126601:
    return true
  case 126603 ..= 126619:
    return true
  case 126625 ..= 126627:
    return true
  case 126629 ..= 126633:
    return true
  case 126635 ..= 126651:
    return true
  case 127232 ..= 127244:
    return true
  case 130032 ..= 130041:
    return true
  case 131072 ..= 173789:
    return true
  case 173824 ..= 177972:
    return true
  case 177984 ..= 178205:
    return true
  case 178208 ..= 183969:
    return true
  case 183984 ..= 191456:
    return true
  case 194560 ..= 195101:
    return true
  case 196608 ..= 201546:
    return true
  }
  return false
}

is_ascii_word :: proc(token: rune) -> bool {
  // matches word regex "\w" flag="ASCII"
  switch u32(token) {
  case 48 ..= 57:
    return true
  case 65 ..= 90:
    return true
  case 95:
    return true
  case 97 ..= 122:
    return true
  }
  return false
}

is_utf8_decimal :: proc(token: rune) -> bool {
  // matches decimal regex "\d"
  switch u32(token) {
  case 48 ..= 57:
    return true
  case 1632 ..= 1641:
    return true
  case 1776 ..= 1785:
    return true
  case 1984 ..= 1993:
    return true
  case 2406 ..= 2415:
    return true
  case 2534 ..= 2543:
    return true
  case 2662 ..= 2671:
    return true
  case 2790 ..= 2799:
    return true
  case 2918 ..= 2927:
    return true
  case 3046 ..= 3055:
    return true
  case 3174 ..= 3183:
    return true
  case 3302 ..= 3311:
    return true
  case 3430 ..= 3439:
    return true
  case 3558 ..= 3567:
    return true
  case 3664 ..= 3673:
    return true
  case 3792 ..= 3801:
    return true
  case 3872 ..= 3881:
    return true
  case 4160 ..= 4169:
    return true
  case 4240 ..= 4249:
    return true
  case 6112 ..= 6121:
    return true
  case 6160 ..= 6169:
    return true
  case 6470 ..= 6479:
    return true
  case 6608 ..= 6617:
    return true
  case 6784 ..= 6793:
    return true
  case 6800 ..= 6809:
    return true
  case 6992 ..= 7001:
    return true
  case 7088 ..= 7097:
    return true
  case 7232 ..= 7241:
    return true
  case 7248 ..= 7257:
    return true
  case 42528 ..= 42537:
    return true
  case 43216 ..= 43225:
    return true
  case 43264 ..= 43273:
    return true
  case 43472 ..= 43481:
    return true
  case 43504 ..= 43513:
    return true
  case 43600 ..= 43609:
    return true
  case 44016 ..= 44025:
    return true
  case 65296 ..= 65305:
    return true
  case 66720 ..= 66729:
    return true
  case 68912 ..= 68921:
    return true
  case 69734 ..= 69743:
    return true
  case 69872 ..= 69881:
    return true
  case 69942 ..= 69951:
    return true
  case 70096 ..= 70105:
    return true
  case 70384 ..= 70393:
    return true
  case 70736 ..= 70745:
    return true
  case 70864 ..= 70873:
    return true
  case 71248 ..= 71257:
    return true
  case 71360 ..= 71369:
    return true
  case 71472 ..= 71481:
    return true
  case 71904 ..= 71913:
    return true
  case 72016 ..= 72025:
    return true
  case 72784 ..= 72793:
    return true
  case 73040 ..= 73049:
    return true
  case 73120 ..= 73129:
    return true
  case 92768 ..= 92777:
    return true
  case 93008 ..= 93017:
    return true
  case 120782 ..= 120831:
    return true
  case 123200 ..= 123209:
    return true
  case 123632 ..= 123641:
    return true
  case 125264 ..= 125273:
    return true
  case 130032 ..= 130041:
    return true
  }
  return false
}

is_ascii_decimal :: proc(token: rune) -> bool {
  // matches decimal regex "\d" flag="ASCII"
  switch u32(token) {
  case 48 ..= 57:
    return true
  }
  return false
}
