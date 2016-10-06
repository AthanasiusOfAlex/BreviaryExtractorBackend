#/bin/bash

ToolName=downloader
KindleName=kindlegen
ProjectName=$2
RootDir=`echo $1 | rev | cut -c 2- | rev`   # This just removes the final / from the path.
Platform=osx
ProjectDir=${RootDir}/${ProjectName}
OutputDir=${RootDir}/obj/${Platform}/${ToolName}
PyInstaller=/opt/local/Library/Frameworks/Python.framework/Versions/3.5/bin/pyinstaller
SourceDir=${ProjectDir}/scripts
Source=${SourceDir}/${ToolName}.py
KindleExe=${SourceDir}/${KindleName}.exe
Product=${OutputDir}/dist/${ToolName}
BinDir=${RootDir}/bin/${Platform}
BinResourceDir=${BinDir}/resources

echo SourceDir: ${SourceDir}
mkdir -p ${OutputDir}
mkdir -p ${BinResourceDir}

## Make the downloader and copy to target resource directory.
#cd ${OutputDir}
#${PyInstaller} ${Source} --onefile
#cp ${Product} ${BinResourceDir}

# Copy the kindlegen program to the resource directory.
cp ${SourceDir}/${KindleName} ${BinResourceDir}