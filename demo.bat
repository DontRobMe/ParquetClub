@echo off
setlocal
pushd "%~dp0"
chcp 65001 >nul
set "NODE_USE_SYSTEM_CA=1"
where node >nul 2>&1
if errorlevel 1 (
  echo Node.js est requis pour lancer la demo Firebase.
  pause
  popd
  exit /b 1
)
call npx --yes --package firebase-tools@15.37.0 -- node scripts\demo\lancer.mjs %*
set "DEMO_EXIT=%ERRORLEVEL%"
if "%~1"=="" pause
popd
exit /b %DEMO_EXIT%
