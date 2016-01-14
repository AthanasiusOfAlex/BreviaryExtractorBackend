#/bin/bash

PackageName=$3
ToolName=downloader
ProjectName=$2
RootDir=`echo $1 | rev | cut -c 2- | rev`   # This just removes the final / from the path.
ProjectDir=${RootDir}/${ProjectName}
OutputDir=${RootDir}/obj/${ToolName}
PyInstaller=/opt/local/Library/Frameworks/Python.framework/Versions/3.5/bin/pyinstaller
SourceDir=${ProjectDir}/resources
Source=${SourceDir}/${ToolName}.py
Product=${OutputDir}/dist/${ToolName}
BinDir=${RootDir}/bin
BinResourceDir=${BinDir}/resources

echo BinDir: ${BinDir}
echo BinResourceDir: ${BinResourceDir}

mkdir -p ${BinResourceDir}
#cd ${BinDir}
#shopt -s extglob                          # Allows using regular expressions.
#mv !(${PackageName}) ${BinResourceDir}    # Move everything but the executible to the resource directory.