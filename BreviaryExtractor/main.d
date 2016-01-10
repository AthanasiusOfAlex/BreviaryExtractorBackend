module main;

import std.path;
import std.range;
import std.stdio;
import std.string;
import std.traits;

import lm.datehelper;
import lm.userfolders;

import config;
import converttokindle;
import day;
import downloadhour;
import filemanager;
import processcommandline;
import progressindicator;


int main(string[] args)
{
	try
	{
		options = new Options(args);
	}
	catch(Exception exc)
	{
		import std.path;

		stderr.writeln(exc.msg);
		stderr.writeln;
		stderr.writeln("Available options:");
		stderr.writefln("    --%-13s %s", "language", "the language to use (it|en|es|fr|pt|ro|ar|ra|la|vt)");
		stderr.writefln("    --%-13s %s", "numberOfDays", "how many days to download");
		stderr.writefln("    --%-13s %s", "startDate", "when to start (yyyy-mm-dd or yyyy-mmm-dd)");
		stderr.writefln("    --%-13s %s", "packageBy", "package by day, week, or month");
		stderr.writefln("    --%-13s %s", "saveToFolder", "which folder to download the MOBI files to");
		stderr.writefln("    --%-13s %s", "openInCalibre", "open in Calibre (yes|no)");
		return 1;
	}

	try
	{
		manageFiles();
	}
	catch(Exception exc)
	{
		stderr.writeln(exc.msg);
		stderr.writeln;
		stderr.writefln("There was a problem creating the folder %s", options.saveToFolder);
		return 1;
	}

	auto progressIndicator = new ProgressIndicator!ProgressEmitNumbers(options.numberOfDays * EnumMembers!Hora.length, 70);
	downloader = new Downloader();

	foreach(date; take(dateGenerator(options.startDate), options.numberOfDays))
	{
		auto day = new Day(date, options.language, progressIndicator);

		// I just need these to go out of scope before I convert them.
		{
			
			auto mainFile = File(buildPath(options.saveToFolder, day.mainFileName), "w");
			mainFile.writeln(day.text);

			auto tocFile = File(buildPath(options.saveToFolder, day.tocFileName), "w");
			tocFile.writeln(day.tocFile);

			auto opfFile = File(buildPath(options.saveToFolder, day.opfFileName), "w");
			opfFile.writeln(day.opfFile);
		}

		convertToKindle(day, options.saveToFolder);
	}

	cleanUpFolder(options.saveToFolder);

	return 0;
}