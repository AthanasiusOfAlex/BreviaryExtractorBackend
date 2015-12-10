/**
 * This module downloads an hour.
 * The main API is the downloadHour()
 * function.
 */

module downloadhour;

import std.string;
import std.datetime;

import config;
import config;

/**
 * Returns the raw hour from the website,
 * based on a date and an hour.
 * There is no processing done.
 */
string downloadHour(Date date, Hora hora, Language language)
{
	import std.conv;
	import std.file;
	import std.path;
	import std.process;
	import lm.tidyinterface;
	import lm.userfolders;



	auto downloader = buildPath(getCurrentWorkingFolder, downloaderScript);
	if (!exists(downloader))
	{
		throw new Exception(`The downloader, '` ~ downloaderScript ~ `', does not exist. Please reinstall.`);
	}
	
	// Download the hour.
	auto downloadProcess = execute(
		[pythonExecutable,
			downloader,
			`-`, date.year.to!string,
			date.month.to!uint.to!string,
			date.day.to!string,
			language.to!string,
			hora.to!string]);
	
	if (downloadProcess.status == 5)
	{
		throw new Exception(`Unable to access the Internet.`);
	}
	else if (downloadProcess.status != 0)
	{
		throw new Exception(`Downloader returned status ` ~
			downloadProcess.status.to!string ~
			` and could not be run.\n` ~
			`Output: "` ~ downloadProcess.output ~ `"`);
	}
	// downloadprocess.status == 0.
	
	return downloadProcess.output;
}


import std.stdio;
/**
 * An alternative version in order to
 * test offline
 */
string downloadHour(File file)
{
	string contents;

	foreach(line; file.byLine(KeepTerminator.yes))
	{
		contents ~= line;
	}

	return contents;
}

/**
 * An alternative version in order to
 * test offline (using the file name).
 */
string downloadHour(string fileName)
{
	auto file = File(fileName);

	return downloadHour(file);
}