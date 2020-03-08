;==============================================================
; Custom functions
Function ConvertBStoDBS
 Exch $R0 ;input string
 Push $R1
 Push $R2
 StrCpy $R1 0
loop:
  IntOp $R1 $R1 - 1
  StrCpy $R2 $R0 1 $R1
  StrCmp $R2 "" done
 StrCmp $R2 "\" 0 loop
  StrCpy $R2 $R0 $R1 ;part before
   Push $R1
  IntOp $R1 $R1 + 1
  StrCpy $R1 $R0 "" $R1 ;part after
 StrCpy $R0 "$R2\\$R1"
   Pop $R1
  IntOp $R1 $R1 - 1
Goto loop
done:
   Pop $R2
   Pop $R1
   Exch $R0 ;output string
FunctionEnd
