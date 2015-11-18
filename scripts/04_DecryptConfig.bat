@echo off
REM Encrypt the AppSettings section of the web.config in
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -pdf appSettings %~dp0ExampleApp
pause