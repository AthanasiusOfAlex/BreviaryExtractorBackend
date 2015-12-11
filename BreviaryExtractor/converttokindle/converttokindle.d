module converttokindle;

import std.algorithm;
import std.file;
import std.format;
import std.path;
import std.process;

import lm.regexhelper;
import lm.userfolders;

import config;
import day;


void convertToKindle(Day day, string outputFolder)
{
	static if (convertToMobi==ConvertToMobi.yes)
	{
		if (!exists(kindleGenExecutable))
		{
			throw new Exception(format(`The kindlegen program (, '%',) does not exist. Please reinstall.`), kindleGenExecutable);
		}

		auto convertProcess = execute([kindleGenExecutable, buildPath(outputFolder, day.opfFileName)]);
	}

	// Remove the data files.
	static if (cleanDataFiles==CleanDataFiles.yes)
	{
		buildPath(outputFolder, day.opfFileName).remove;
		buildPath(outputFolder, day.tocFileName).remove;
		buildPath(outputFolder, day.mainFileName).remove;
	}
}

/**
 * Cleans up any remaining files.
 * Warning! CSS files will be deleted!
 */
void cleanUpFolder(string folder)
{
	static if (cleanDataFiles==CleanDataFiles.yes)
	{
		foreach (string file; folder.dirEntries(SpanMode.shallow).filter!(a=>a.extension.isMatchOf!`(css)|(CSS)`))
		{
			file.remove;
		}
	}
}

