@echo off
REM Grant Local User Account Permission to Container
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -pa MyContainer "%userdomain%\%username%"
pause