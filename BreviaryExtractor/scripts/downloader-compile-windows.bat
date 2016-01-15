@echo off

set ToolName=downloader
set KindleName=kindlegen
set ProjectName=%2


set RootDir=%1
set Platform=windows
set ProjectDir=%RootDir%%ProjectName%
set OutputDir=%RootDir%obj\%Platform%\%ToolName%
set PyInstaller=pyinstaller
set SourceDir=%ProjectDir%\scripts
set Source=%SourceDir%\%ToolName%.py
set KindleExe=%SourceDir%\%KindleName%.exe
set Product=%OutputDir%\dist\%ToolName%.exe
set BinDir=%RootDir%bin\%Platform%
set BinResourceDir=%BinDir%\resources

mkdir %OutputDir%
mkdir %BinResourceDir%

rem Make the downloader and copy to target resource directory.
cd /d %OutputDir%
%PyInstaller% %Source% --onefile
copy %Product% %BinResourceDir%

rem Copy the kindlegen program to the resource directory.
copy %KindleExe% %BinResourceDir%

rem Copy the 'tidy' dll to the program directory.
copy %SourceDir%\tidy.dll %BinDir%