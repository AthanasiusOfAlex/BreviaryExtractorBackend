#/bin/bash

ToolName=downloader
ProjectName=$2
RootDir=`echo $1 | rev | cut -c 2- | rev`   # This just removes the final / from the path.
ProjectDir=${RootDir}/${ProjectName}
OutputDir=${RootDir}/obj/${ToolName}
PyInstaller=/opt/local/Library/Frameworks/Python.framework/Versions/3.5/bin/pyinstaller
SourceDir=${ProjectDir}/scripts
Source=${SourceDir}/${ToolName}.py
Product=${OutputDir}/dist/${ToolName}
BinDir=${RootDir}/bin
BinResourceDir=${BinDir}/resources

echo OutputDir: ${OutputDir}
mkdir -p ${OutputDir}
mkdir -p ${BinResourceDir}

# Make the downloader and copy to target resource directory.
cd ${OutputDir}
${PyInstaller} ${Source} --onefile
cp ${Product} ${BinResourceDir}
