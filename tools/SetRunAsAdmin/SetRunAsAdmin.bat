@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
title 批量设置以管理员身份运行

set /a OK_COUNT=0
set /a FAIL_COUNT=0
set /a SKIP_COUNT=0
set /a TOTAL_COUNT=0

if "%~1"=="" goto prompt

:arg_loop
if "%~1"=="" goto done
call :process "%~1"
shift
goto arg_loop

:prompt
echo 把一个或多个 .exe / .lnk 文件拖进这个窗口，然后按 Enter。
echo 也可以直接把多个文件一起拖到这个 .bat 文件图标上。
echo.
set /p "INPUT_PATH=路径: "
if "%INPUT_PATH%"=="" goto no_input
for %%I in (%INPUT_PATH%) do call :process "%%~I"
goto done

:no_input
echo [失败] 没有输入任何路径。
set /a FAIL_COUNT+=1
goto done

:process
set "ITEM=%~1"
set /a TOTAL_COUNT+=1

if exist "%ITEM%" goto item_exists
echo [失败] 文件不存在或路径无法访问：%ITEM%
set /a FAIL_COUNT+=1
exit /b 1

:item_exists
if not exist "%ITEM%\" goto item_is_file
echo [跳过] 这是文件夹，不是程序或快捷方式：%ITEM%
set /a SKIP_COUNT+=1
exit /b 0

:item_is_file
set "EXT=%~x1"
if /I "%EXT%"==".exe" goto process_exe
if /I "%EXT%"==".lnk" goto process_lnk

echo [跳过] 不支持的文件类型：%ITEM%
echo        目前只支持 .exe 和 .lnk。
set /a SKIP_COUNT+=1
exit /b 0

:process_exe
call :set_exe_runas "%ITEM%"
if errorlevel 1 goto exe_failed
echo [成功] 已设置以管理员身份运行：%ITEM%
set /a OK_COUNT+=1
exit /b 0

:exe_failed
echo [失败] 写入兼容性设置失败：%ITEM%
echo        提示：请确认文件路径存在，并且当前用户可以写入注册表兼容性设置。
set /a FAIL_COUNT+=1
exit /b 1

:process_lnk
call :set_lnk_runas "%ITEM%"
if errorlevel 1 goto lnk_failed
echo [成功] 已设置快捷方式以管理员身份运行：%ITEM%
echo        说明：这会修改快捷方式自身；如果你还想设置原始程序，请把它指向的 .exe 也拖进来。
set /a OK_COUNT+=1
exit /b 0

:lnk_failed
echo [失败] 修改快捷方式失败：%ITEM%
echo        提示：如果快捷方式在系统目录里，请先复制到桌面再处理，或右键用管理员权限运行本脚本。
set /a FAIL_COUNT+=1
exit /b 1

:set_exe_runas
set "RUNASADMIN_ITEM=%~1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $p=$env:RUNASADMIN_ITEM; $reg='HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'; $cur=$null; $out=& reg.exe query $reg /v $p 2>$null; if($LASTEXITCODE -eq 0){ foreach($line in $out){ $idx=$line.IndexOf('REG_SZ'); if($idx -ge 0){ $cur=$line.Substring($idx + 6).Trim(); break } } }; $hasRunAs=$false; if(-not [string]::IsNullOrWhiteSpace($cur)){ foreach($part in ($cur -split '\s+')){ if($part -ieq 'RUNASADMIN'){ $hasRunAs=$true } } }; if([string]::IsNullOrWhiteSpace($cur)){ $next='~ RUNASADMIN' } elseif($hasRunAs){ $next=$cur } elseif($cur.TrimStart().StartsWith('~')){ $next=$cur.TrimEnd() + ' RUNASADMIN' } else { $next='~ ' + $cur.Trim() + ' RUNASADMIN' }; & reg.exe add $reg /v $p /t REG_SZ /d $next /f | Out-Null; if($LASTEXITCODE -ne 0){ throw 'reg.exe 写入失败。' }; exit 0 } catch { Write-Host ('       原因：' + $_.Exception.Message); exit 1 }"
set "RUNASADMIN_ITEM="
exit /b %ERRORLEVEL%

:set_lnk_runas
set "RUNASADMIN_ITEM=%~1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $p=$env:RUNASADMIN_ITEM; $b=[System.IO.File]::ReadAllBytes($p); if($b.Length -lt 76){ throw '快捷方式文件格式异常，长度过短。' }; if([BitConverter]::ToUInt32($b,0) -ne 76){ throw '快捷方式文件头异常，可能不是有效的 .lnk 文件。' }; $clsid=[byte[]](1,20,2,0,0,0,0,0,192,0,0,0,0,0,0,70); for($i=0; $i -lt $clsid.Length; $i++){ if($b[$i+4] -ne $clsid[$i]){ throw '快捷方式标识异常，可能不是有效的 .lnk 文件。' } }; $b[21]=$b[21] -bor 32; [System.IO.File]::WriteAllBytes($p,$b); exit 0 } catch { Write-Host ('       原因：' + $_.Exception.Message); exit 1 }"
set "RUNASADMIN_ITEM="
exit /b %ERRORLEVEL%

:done
echo.
echo 结果：成功 %OK_COUNT% 个，失败 %FAIL_COUNT% 个，跳过 %SKIP_COUNT% 个。
if %OK_COUNT% GTR 0 echo 提示：设置作用于当前 Windows 用户。启动程序时如果弹出 UAC，请选择“是”。

if %FAIL_COUNT% GTR 0 goto finish_bad
if %OK_COUNT% EQU 0 goto finish_bad
goto finish_ok

:finish_bad
if not "%RUNASADMIN_BAT_NOPAUSE%"=="1" pause
exit /b 1

:finish_ok
if not "%RUNASADMIN_BAT_NOPAUSE%"=="1" pause
exit /b 0
