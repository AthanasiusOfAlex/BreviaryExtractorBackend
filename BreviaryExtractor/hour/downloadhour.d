/**
 * This module downloads an hour.
 * The main API is the downloadHour()
 * function.
 */

module downloadhour;

import std.string;
import std.datetime;

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
	import std.format;
	import std.path;
	import std.process;
	import lm.tidydocument;
	import lm.userfolders;



	if (!exists(downloadExecutible))
	{
		throw new Exception(format(`%s, does not exist. Please reinstall.`, downloadExecutible));
	}
	
	// Download the hour.
	auto shellCommand = format(
		`%s %s %s %s %s %s %s`,
		downloadExecutible,
		`-`,
		date.year,
		date.month.to!uint,
		date.day,
		language,
		hora);

	auto downloadProcess = executeShell(shellCommand);
	
	if (downloadProcess.status == 5)
	{
		throw new Exception(format(`Unable to access the Internet. Output: %s`, downloadProcess.output));
	}
	else if (downloadProcess.status != 0)
	{
		throw new Exception(format(
				`Downloader returned status %s and could not be run.\nOutput: %s`,
				downloadProcess.status,
				downloadProcess.output));
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