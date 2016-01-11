module config;

import std.conv;
import std.datetime;
import std.path;
import std.traits;

import lm.userfolders;
import lm.tidydocument;

import config;
import downloadhour;
import processcommandline;

immutable earliestDate = Date(1970, Month.jan, 1);
immutable countStarting = CountStarting.today;
immutable convertToMobi = ConvertToMobi.yes;
immutable cleanDataFiles = CleanDataFiles.yes;
immutable resourceFolder = `resources`;

immutable kindleGenExecutable = buildPath(resourceFolder, `kindlegen`);
immutable downloadExecutible = buildPath(resourceFolder, `downloader`);
immutable opfTemplate = buildPath(resourceFolder, `metadata.opf.template`);
immutable tocTemplate = buildPath(resourceFolder, `toc.ncx.template`);
immutable cssFile = buildPath(`breviarystyle.css`);
immutable cssFileTemplate = buildPath(resourceFolder, cssFile);

public Options options;
public Downloader downloader;

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

public mixin template ExceptionCtorMixin() {
	this(string msg = null, Throwable next = null) { super(msg, next); }
	this(string msg, string file, size_t line, Throwable next = null) {
		super(msg, file, line, next);
	}
}