@echo off
REM This will not work
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -pdf incorrectConfigSection %~dp0ExampleAppBadPath
if %ERRORLEVEL% NEQ 0 echo. && echo Handle the error here!
pause