module filemanager;

import std.algorithm;
import std.file;
import std.path;
import std.stdio;

import lm.regexhelper;
import lm.userfolders;

import config;

void manageFiles()
{
	auto outputFolder = options.saveToFolder;

	void prepareFolder()
	{
		if (!exists(outputFolder))
		{
			mkdirRecurse(outputFolder);
		}
	}

	void copyCssFilesToFolder()
	{
		foreach(file; dirEntries(resourceFolder, SpanMode.shallow).filter!(a => a.name.isMatchOf!`\.css$`))
		{
			copy(file.name, buildPath(outputFolder, file.baseName));
		}
	}

	prepareFolder();
	copyCssFilesToFolder();
}

