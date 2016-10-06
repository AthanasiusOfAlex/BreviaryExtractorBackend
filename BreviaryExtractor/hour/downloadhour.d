/**
 * This module downloads an hour.
 * The main API is the downloadHour()
 * function.
 */

module downloadhour;



import std.algorithm.iteration;
//import std.concurrency;
import std.conv;
import std.net.curl;
import std.datetime;
import std.file;
import std.process;
import std.range;
import std.stdio;
import std.string;

import lm.regexhelper;

import config;

class DownloaderException : Exception { mixin ExceptionCtorMixin; }
class InternetException: Exception { mixin ExceptionCtorMixin; }
class ProxyException: Exception { mixin ExceptionCtorMixin; }

version(none) {

class Downloader
{
	this()
	{
		open;
		setProxy;
	}

	bool isOpen = false;

	/// Downloads the hour.
	string downloadHour(Date date, Hora hora, Language language)
	{
		auto argument = makeArgument(date, hora, language);

		return relayMessage(argument);
	}

	/// Changes the proxy setting.
	void setProxy()
	{
		string proxyMessage = "";

		if (options.proxy=="" || options.proxy=="None")
		{
			proxyMessage = "proxy None";
		}
		else if (options.proxy.isMatchOf!`https?://([^@:]+:)?([^@:]+@)?[\d\w\.-]+(:\d+)?/?`)
		{
			proxyMessage = format("proxy %s", options.proxy);
		}
		else
		{
			throw new ProxyException(format("An invalid proxy-server address was given: ‘%s’.", options.proxy));
		}

		auto reply = relayMessage(proxyMessage ~ "\n");
	}

	/// Opens the thread.
	void open()
	{
		if (!isOpen)
		{
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

		return format(`download %s %s %s %s %s`,
			date.year,
			date.month.to!uint,
			date.day,
			language,
			hora);
	}

	/// Relays a message and returns the reply.
	string relayMessage(string message)
	{
		makeSureDownloaderIsOpen;
		processManager.send(message);

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

		string result;

		string replyHeader = replyParts.front;
		if (replyHeader.isMatchOf!`(HTML|PROXY)`)
		{
			replyParts.popFront;
			if (!replyParts.empty)
			{
				result = replyParts.front;
			}
		}
		else if (replyHeader=="EXC")
		{
			replyParts.popFront;
			
			// Close off the child thread and throw an exception.
			close;
			
			if (!replyParts.empty)
			{
				// Isolate the internet connection error.
				auto errorMessage = replyParts.front;
				auto errorClassification = errorMessage.splitFirst(`\(`).front;
				
				if (errorClassification=="HTTPConnectionPool")
				{
					throw new InternetException(errorMessage);
				}
				else
				{
					throw new DownloaderException(errorMessage);
				}
			}
			else
			{
				throw new DownloaderException("Unspecified error given by downloader application.");
			}
		}
		else
		{
			throw new DownloaderException(format("Unknown reply '%s' given from downloader application.", reply));
		}

		return result;
	}

	void makeSureDownloaderIsOpen()
	{
		if (!isOpen)
		{
			throw new DownloaderException("Attempt to use the Downloader when it is closed. Please open it first.");
		}
	}
}

private:
void manageExternalProcess()
{
	ProcessPipes pipes;

	try
	{
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

			if (messageReceived=="")
			{
				throw new DownloaderException("You sent me an empty string. That is invalid.");
			}

			string messageHeader = messageReceived.splitter.front;

			if (!messageHeader.isMatchOf!`(quit|download|proxy)`)
			{
				throw new DownloaderException("The only message headers allowed are 'quit', 'download', and 'proxy'");
			}

			if (messageHeader=="quit")
			{
				break;
			}
			else
			{
				// Make sure the message is properly constructed.
				auto messageLength = messageReceived.splitter.array.length;
				if (messageHeader=="download" && messageLength!=6)
				{
					throw new DownloaderException("Download messages should always have six arguments: 'download', year, month, day, language, hour.");
				}
				// Make sure the message is properly constructed.
				if (messageHeader=="download" && messageLength!=6)
				{
					throw new DownloaderException("Proxy messages should always have two arguments: 'proxy' and the proxy server.");
				}

				// Send it in to the scraper. (I will close the stdio stream later.)
				pipes.stdin.writeln(messageReceived);
				pipes.stdin.flush;

				// Wait for the reply.
				string reply = pipes.stdout.byLine.front.idup;

				// Send the reply back to the owner thread.
				ownerTid.send(reply);
			}
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

}

class Downloader {

private:

	immutable string baseURL = "http://www.ibreviary.com/m2/";
	immutable string breviaryURL = baseURL ~ "breviario.php?s=";
	immutable string[Hora] hourNames;
	string proxy = "http://gateway.zscaler.net:80";
	HTTP client;
	Date date;
	Hora hora = Hora.office;
	Language language = Language.en;

public:
	
	this() {

		date = cast(Date)Clock.currTime();
		hourNames = [
			Hora.office: "ufficio_delle_letture",
			Hora.lauds: "lodi",
			Hora.daytime: "ora_media",
			Hora.vespers: "vespri",
			Hora.complines: "compieta"
		];
		client = HTTP();
		client.proxy = proxy;

	}

	@property string downloadHour() {

		string data = format(
			"lang=%s&anno=%s&mese=%s&giorno=%s&ok=ok",
			language,
			date.year,
			date.month.to!int,
			date.day);

		return "";
	
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

	downloader.date = date;
	downloader.hora = hora;
	downloader.language = language;

	return downloader.downloadHour;

}