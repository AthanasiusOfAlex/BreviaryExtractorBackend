#/bin/sh
ToolName=downloader
OutputDir=${ProjectDir}/obj/${ReleaseType}/${ToolName}
PyInstaller=/opt/local/Library/Frameworks/Python.framework/Versions/3.5/bin/pyinstaller
SourceDir=${ProjectDir}/resources
Source=${SourceDir}/${ToolName}.py

mkdir -p ${OutputDir}
cd ${OutputDir}
${PyInstaller} ${Source} --outfile
