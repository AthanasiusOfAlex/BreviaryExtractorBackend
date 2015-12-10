module config;

import std.conv;
import std.datetime;
import std.path;
import std.traits;

import lm.userfolders;

import config;
import processcommandline;

immutable Date earliestDate = Date(1970, Month.jan, 1);
immutable CountStarting countStarting = CountStarting.today;
immutable pythonExecutable = `/opt/local/bin/python2.7`;
immutable ConvertToMobi convertToMobi = ConvertToMobi.yes;
immutable downloaderScript = `downloader.py`;
immutable CleanDataFiles cleanDataFiles = CleanDataFiles.yes;

immutable opfTemplate = "metadata.opf.template";
immutable tocTemplate = "toc.ncx.template";
immutable cssFile = "breviarystyle.css";

public Options options;


enum Hora
{
	office,
	lauds,
	daytime,
	vespers,
	complines
}

string horaFullTitle(Hora hora, Language language)
{
	string[string] titles = [
		"office": "Office of Readings",
		"lauds": "Morning Prayer",
		"daytime": "Daytime Prayers",
		"vespers": "Evening Prayer",
		"complines": "Night Prayer"
	];
	
	return titles[hora.to!string];
}

enum Language
{
	it,
	en,
	es,
	fr,
	pt,
	ro,
	ar,
	ra,
	la,
	vt
}

enum SaveToCalibre
{
	yes,
	no
}

enum PackageBy
{
	day,
	week,
	month
}

enum ConvertToMobi
{
	yes,
	no
}


enum CleanDataFiles
{
	yes,
	no,
}

enum CountStarting
{
	today,
	tomorrow
}

//Date startDate()
//{
//	static if (countStarting==CountStarting.today)
//	{
//		return cast(Date)Clock.currTime + dur!"days"(0);
//	}
//	else
//	{
//		return cast(Date)Clock.currTime + dur!"days"(1);	// i.e., tomorrow.
//	}
//}


/**
 * Returns the next enum after the current one.
 * Loops around after the last enum.
 */
R nextEnum(R)(R currentEnum)
{
	return advanceInEnum(currentEnum, 1);
}

/**
 * Returns the previous enum before the current
 * one. Loops around after the last enum.
 */
R previousEnum(R)(R currentEnum)
{
	return advanceInEnum(currentEnum, -1);
}

/**
 * Advances 'increment' places in an enum.
 * Use negative values to backtrack.
 * Loops around if it reaches the end.
 */
private R advanceInEnum(R)(R currentEnum, int increment)
{
	import std.traits;
	
	auto enumSize = [EnumMembers!R].length;
	
	// Get index of currentEnum:
	uint currentEnumIdx;
	foreach(immutable idx, immutable mem; EnumMembers!R)
	{
		if (currentEnum==mem)
		{
			currentEnumIdx = idx;
			break;
		}
	}
	
	// Increment current index, but do so modulo the size of the enum type
	// (so that the "next" member after the last member is the first).
	
	// Adujst increment to avoid negatives.
	while (increment<0)
	{
		increment += enumSize;	// Always equivalent, modulo enumSize.
	}
	auto adjustedIncrement = cast(uint)increment;
	
	currentEnumIdx += adjustedIncrement;
	currentEnumIdx %= enumSize;
	
	// Return the resulting enum.
	// We need the [] around EnumMembers!R, because it is a tuple, not
	// an array. A tuple can only take indices known at compile time.
	// Putting [] around it converts it into an array, avoiding the problem.
	return [EnumMembers!R][currentEnumIdx];
}

/**
 * DEPRECATED
 * Use EnumMembers from std.traits instead.
 * EnumMembers!R returns a tuple.
 * Surround by square brackets to get an array.
 * Returns all members of an enum (or any similar
 * structure) as an array.
 */
R[] getAllMembers(R)()
{
	R[] allMembers;
	
	foreach(member; __traits(allMembers, R))
	{
		allMembers ~= mixin(__traits(identifier, R) ~ "." ~ member);
	}
	
	return allMembers;
}