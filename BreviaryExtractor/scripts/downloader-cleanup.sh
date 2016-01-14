#/bin/sh

ToolName=downloader
ProjectDir=$1
ReleaseType=$2
OutputDir=${ProjectDir}/obj/${ReleaseType}/${ToolName}

rm -rf ${OutputDir}
