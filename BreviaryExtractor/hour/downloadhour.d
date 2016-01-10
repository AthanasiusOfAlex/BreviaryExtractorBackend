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
	import std.range;
	import lm.tidydocument;
	import lm.regexhelper;
	import lm.userfolders;

	if (!exists(downloadExecutible))
	{
		throw new Exception(format(`%s, does not exist. Please reinstall.`, downloadExecutible));
	}

	// This argument will retrieve the desired hour.
	auto argument = format(
		`download %s %s %s %s %s`,
		date.year,
		date.month.to!uint,
		date.day,
		language,
		hora);
	
	// Set up the process.
	auto pipes = pipeProcess(downloadExecutible, Redirect.all);
	scope(exit) wait(pipes.pid);

	// Send it in to the scraper and close the stream.
	pipes.stdin.writeln(argument);
	pipes.stdin.close;

	string result="";
	foreach(line; pipes.stdout.byLine)
	{
		pipes.stdout.flush;

		auto splitLine = line.splitFirst(`:\s*`);
		assert(!splitLine.empty);

		if (splitLine.front=="HTML")
		{
			splitLine.popFront;
			if (!splitLine.empty)
			{
				result = splitLine.front;
			}
			break;
		}
		else if (splitLine.front=="EXC")
		{
			splitLine.popFront;
			if (!splitLine.empty)
			{
				throw new Exception(splitLine.front);
			}
			else
			{
				throw new Exception("Unspecified error given by downloader application.");
			}
		}
	}

	return result;
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