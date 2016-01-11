/**
 * This module downloads an hour.
 * The main API is the downloadHour()
 * function.
 */

module downloadhour;



import std.concurrency;
import std.datetime;
import std.stdio;

import config;

class DownloaderException : Exception { mixin ExceptionCtorMixin; }

class Downloader
{
	this()
	{
		open;
	}

	bool isOpen = false;

	/// Downloads the hour.
	string downloadHour(Date date, Hora hora, Language language)
	{
		import std.range;
		import lm.regexhelper;

		if (!isOpen)
		{
			throw new DownloaderException("Attempt to use the Downloader when it is closed. Please open it first.");
		}

		auto argument = makeArgument(date, hora, language);
		processManager.send(argument);
		string reply;

		// Receive the reply (or an exception).
		receive(
			(string message)
			{ 
				reply = message;
			},

			(shared(Exception) exc)
			{
				throw exc;
			});
			
		// Parce and process the reply.
		auto replyParts = reply.splitFirst(`:\s*`);

		string message;
		if (replyParts.front=="HTML")
		{
			replyParts.popFront;
			if (!replyParts.empty)
			{
				message = replyParts.front;
			}
		}
		else if (replyParts.front=="EXC")
		{
			replyParts.popFront;

			// Close off the child thread and throw an exception.
			close;

			if (!replyParts.empty)
			{
				throw new DownloaderException(replyParts.front);
			}
			else
			{
				throw new DownloaderException("Unspecified error given by downloader application.");
			}
		}

		return message;
	}

	/// Opens the thread.
	void open()
	{
		if (!isOpen)
		{
			import std.file;
			import std.string;

			if (!exists(downloadExecutible))
			{
				throw new DownloaderException(format(`%s, does not exist. Please reinstall.`, downloadExecutible));
			}

			processManager = spawnLinked(&manageExternalProcess);
			isOpen = true;
		}
	}

	/// Closes the thread.
	void close()
	{
		if (isOpen)
		{
			processManager.send("quit");
			isOpen = false;
		}
	}

	// Closes and reopens the thread, to restore sanity if needed.
	void reopen()
	{
		close;
		open;
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
	import std.process;
	import std.range;

	ProcessPipes pipes;

	try {
		// Set up the process.
		pipes = pipeProcess(downloadExecutible, Redirect.all);

		scope(exit)
		{
			if (pipes.stdin.isOpen)
			{
				pipes.stdin.close;
			}
			wait(pipes.pid);
		}

		while(true)
		{
			auto messageReceived = receiveOnly!string();

			if (messageReceived=="quit")
			{
				break;
			}

			// Make sure the message is properly constructed.
			assert(messageReceived.splitter.front=="download", "Messages should always begin with 'download'.");
			assert(messageReceived.splitter.array.length==6, "Messages should always have six arguments: 'download', year, month, day, language, hour.");

			// Send it in to the scraper. (I will close the stdio stream later.)
			pipes.stdin.writeln(messageReceived);
			pipes.stdin.flush;

			// Wait for the reply.
			string reply = pipes.stdout.byLine.front.idup;

			// Send the reply back to the owner thread.
			ownerTid.send(reply);
		}
	}
	catch (OwnerTerminated exc)
	{
		// No need to do anything if the owner does not exist. Just exit.
		// (This catch is necessary to avoid attempting to message the
		// owner when it no longer exists.)
	}
	catch (shared(Exception) exc)
	{
		// Send it back to the owner.
		ownerTid.send(exc);
	}

}

public:
/**
 * A convenience function that 
 * returns the raw hour from the website,
 * based on a date and an hour.
 * There is no processing done.
 */
string downloadHour(Date date, Hora hora, Language language)
{
	return downloader.downloadHour(date, hora, language);
}