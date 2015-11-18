@echo off
REM Exports Key Container to an XML File
if not exist %~dp0ExportedContainers\ mkdir %~dp0ExportedContainers\
%windir%\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -px MyContainer %~dp0ExportedContainers\MyContainer.xml -pri
pause