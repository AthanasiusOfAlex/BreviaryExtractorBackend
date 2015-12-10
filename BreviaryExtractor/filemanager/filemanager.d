module filemanager;

import std.algorithm;
import std.file;
import std.path;
import std.stdio;

import lm.regexhelper;
import lm.userfolders;

void manageFiles(string outputFolder)
{
	void prepareFolder()
	{
		if (!exists(outputFolder))
		{
			mkdirRecurse(outputFolder);
		}
	}

	void copyCssFilesToFolder()
	{
		foreach(file; dirEntries(getCurrentWorkingFolder(), SpanMode.shallow).filter!(a => a.name.isMatchOf!`\.css$`))
		{
			copy(file.name, buildPath(outputFolder, file.baseName));
		}
	}

	prepareFolder();
	copyCssFilesToFolder();
}

