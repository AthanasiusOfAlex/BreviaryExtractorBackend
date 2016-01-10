/**
 * This module downloads an hour.
 * The main API is the downloadHour()
 * function.
 */

module downloadhour;

import std.concurrency;
import std.datetime;

import config;

class Downloader
{
	this()
	{
		processManager = spawn(&manageExternalProcess);
	}

	/// Downloads the hour.
	string downloadHour(Date date, Hora hora, Language language)
	{
		auto argument = makeArgument(date, hora, language);
		processManager.send(argument);
		return receiveOnly!string();
	}

	/// Closes the process.
	void close()
	{
		processManager.send("quit");
	}

private:
	Tid processManager;

	/// This argument will retrieve the desired hour.
	string makeArgument(Date date, Hora hora, Language language)
	{
		import std.conv;
		import std.string;

		return format(`download %s %s %s %s %s`,
			date.year,
			date.month.to!uint,
			date.day,
			language,
			hora);
	}
}

private:
void manageExternalProcess()
{
	import std.file;
	import std.path;
	import std.process;
	import std.range;
	import std.string;
	import std.utf;
	import lm.regexhelper;

	if (!exists(downloadExecutible))
	{
		throw new Exception(format(`%s, does not exist. Please reinstall.`, downloadExecutible));
	}

	// Set up the process.
	auto pipes = pipeProcess(downloadExecutible, Redirect.all);
	scope(exit) wait(pipes.pid);

	while(true)
	{
		auto messageReceived = receiveOnly!string();

		if (messageReceived=="quit")
		{
			pipes.stdin.close;
			break;
		}

		// Make sure the message is properly constructed.
		assert(messageReceived.splitter.front=="download", "Messages should always begin with 'download'.");
		assert(messageReceived.splitter.array.length==6, "Messages should always have six arguments: 'download', year, month, day, language, hour.");

		// Send it in to the scraper. (I will close the stdio stream later.)
		pipes.stdin.writeln(messageReceived);
		pipes.stdin.flush;

		// Wait for the reply.
		auto replyParts = pipes.stdout.byLine.front.splitFirst(`:\s*`);
		string reply;

		if (replyParts.front=="HTML")
		{
			replyParts.popFront;
			if (!replyParts.empty)
			{
				reply = replyParts.front;
			}
		}
		else if (replyParts.front=="EXC")
		{
			replyParts.popFront;
			if (!replyParts.empty)
			{
				throw new Exception(replyParts.front);
			}
			else
			{
				throw new Exception("Unspecified error given by downloader application.");
			}
		}

		// Send the reply back to the owner thread.
		ownerTid.send(reply);
	}
}

public:
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
	import lm.regexhelper;

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