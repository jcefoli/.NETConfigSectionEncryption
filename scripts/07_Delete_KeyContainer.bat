@echo off
REM Deletes the Key Container called "MyContainer" on your local computer
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -pz MyContainer

REM Also delete the file:
del /s %~dp0ExportedContainers\MyContainer.xml
pause