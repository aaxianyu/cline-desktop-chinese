@echo off
rem cline-zh launcher - start Cline with the Chinese localization injected.
rem Requirement: Cline must be fully closed before running this script.
cd /d "%~dp0"
where node >nul 2>nul || (echo [cline-zh] Node.js not found. Install Node.js first. & pause & exit /b 1)
node cline-zh.mjs run
pause
