#/bin/sh

ToolName=downloader
ProjectDir=$1
ReleaseType=$2
OutputDir=${ProjectDir}/obj/${ReleaseType}/${ToolName}
PyInstaller=/opt/local/Library/Frameworks/Python.framework/Versions/3.5/bin/pyinstaller
SourceDir=${ProjectDir}/resources
Source=${SourceDir}/${ToolName}.py
Product=${OutputDir}/dist/${ToolName}
BinResourceDir=${ProjectDir}/bin/${ReleaseType}/resources

echo ${OutputDir}

mkdir -p ${OutputDir}
cd ${OutputDir}
${PyInstaller} ${Source} --onefile

cp ${Product} ${BinResourceDir}
