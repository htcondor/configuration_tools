echo off

REM leave a pid file so that a non-DC process
REM like configd can be notified for shutdown

copy /y /nul > %cd%\.pid%1
REM set this sleep value to be at least twice
REM as long as the QMF_CONFIGD_WIN_INTERVAL
SLEEP 6
EXIT /B 0