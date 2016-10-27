@if not defined _echo @echo off
setlocal

if not defined VisualStudioVersion (
  if defined VS140COMNTOOLS (
    call "%VS140COMNTOOLS%\VsDevCmd.bat"
    goto :Run
  )
  echo Error: Visual Studio 2015 required.
  echo        Please see https://github.com/dotnet/corefx/blob/master/Documentation/project-docs/developer-guide.md for build instructions.
  exit /b 1
)

:Run
:: Clear the 'Platform' env variable for this session, as it's a per-project setting within the build, and
:: misleading value (such as 'MCD' in HP PCs) may lead to build breakage (issue: #69).
set Platform=
set TOOLRUNTIME_DIR=%~dp0Tools
set BOOTSTRAP_URL=https://raw.githubusercontent.com/dotnet/buildtools/master/bootstrap/bootstrap.ps1
set BOOTSTRAP_DEST=%TOOLRUNTIME_DIR%\bootstrap.ps1
set /p DOTNET_VERSION=< "%~dp0.cliversion"
set SHARED_FRAMEWORK_VERSION=1.0.0-rc3-002733

:: Run bootstrapper to get buildtools and CLI
set DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
if not exist %TOOLRUNTIME_DIR% (
  mkdir %TOOLRUNTIME_DIR%
)
if not exist %BOOTSTRAP_DEST% (
  powershell -NoProfile -ExecutionPolicy unrestricted -Command "$retryCount = 0; $success = $false; do { try { (New-Object Net.WebClient).DownloadFile('%BOOTSTRAP_URL%', '%BOOTSTRAP_DEST%'); $success = $true; } catch { if ($retryCount -ge 6) { throw; } else { $retryCount++; Start-Sleep -Seconds (5 * $retryCount); } } } while ($success -eq $false)"
)
copy /y D:\Source\dotnet_buildtools\bootstrap\bootstrap.ps1 %BOOTSTRAP_DEST% >NUL
powershell -NoProfile -ExecutionPolicy unrestricted %BOOTSTRAP_DEST% -RepositoryRoot (Get-Location) -SharedFrameworkVersion %SHARED_FRAMEWORK_VERSION%

if NOT [%ERRORLEVEL%]==[0] exit /b 1


echo Updating CLI NuGet Frameworks map...
echo robocopy "%TOOLRUNTIME_DIR%" "%TOOLRUNTIME_DIR%\dotnetcli\sdk\%DOTNET_VERSION%" NuGet.Frameworks.dll /XO
robocopy "%TOOLRUNTIME_DIR%" "%TOOLRUNTIME_DIR%\dotnetcli\sdk\%DOTNET_VERSION%" NuGet.Frameworks.dll /XO >NUL
set UPDATE_CLI_ERRORLEVEL=%ERRORLEVEL%
if %UPDATE_CLI_ERRORLEVEL% GTR 1 (
  echo ERROR: Failed to update Nuget for CLI {Error level %UPDATE_CLI_ERRORLEVEL%}. 1>&2
  exit /b %UPDATE_CLI_ERRORLEVEL%
)

set _dotnet=%TOOLRUNTIME_DIR%\dotnetcli\dotnet.exe

call %_dotnet% %TOOLRUNTIME_DIR%\run.exe %*
exit /b %ERRORLEVEL%
