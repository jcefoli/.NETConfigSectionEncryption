@echo off
REM Imports Key Container from an XML File
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -pi MyContainer %~dp0ExportedContainers\MyContainer.xml
pause