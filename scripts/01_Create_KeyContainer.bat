@echo off
REM Creates a Key Container called "MyContainer" of your local computer
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -pc MyContainer -size 4096 -exp
pause