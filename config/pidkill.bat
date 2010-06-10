echo off

REM leave a pid file so that a non-DC process
REM like configd can be notified for shutdown

copy /y nul > %cd%\.pid%1

REM set this sleep value to be at least twice
REM as long as the QMF_CONFIGD_WIN_INTERVAL
set cntr=0

:LoopStart
IF NOT EXIST %cd%\.pid%1 Goto EndClean
ping 127.0.0.1 -n 1 -w 1000 > nul
IF %cntr%==5 Goto EndBad
set /A cntr=%cntr%+1
Goto LoopStart

:EndClean
REM Give an extra second to clean up
ping 127.0.0.1 -n 1 -w 1000 > nul
EXIT /B 0

:EndBad
EXIT /B 1