module processcommandline;

import std.algorithm.iteration;
import std.datetime;
import std.getopt;
import std.path;
import std.range;

import lm.userfolders;

import publicenums;
import config;

class Options {

	@property Language language() { return mLanguage; }
	@property int numberOfDays() { return mNumberOfDays; }
	@property Date startDate() { return mStartDate; }
	@property PackageBy packageBy() { return mPackageBy; }
	@property string saveToFolder() { return mSaveToFolder; }
	@property SaveToCalibre openInCalibre() { return mSaveToCalibre; }

	this(ref string[] args)
	{
		switch (countStarting)
		{
			case CountStarting.today:
				mStartDate = today();
				break;

			default:
				mStartDate = tomorrow();
		}

		mSaveToFolder = getCurrentWorkingFolder();

		getopt(
			args,
			language.stringof.baseName, &mLanguage,
			numberOfDays.stringof.baseName, &mNumberOfDays,
			startDate.stringof.baseName, &mStartDateString,
			packageBy.stringof.baseName, &mPackageBy,
			saveToFolder.stringof.baseName, &mSaveToFolder,
			openInCalibre.stringof.baseName, &mSaveToCalibre);

		mSaveToFolder = mSaveToFolder.expandTilde;

		if (!mStartDateString.empty)
		{
			mStartDate = toDate(mStartDateString);
		}
	}

private:
	Language mLanguage = Language.en;
	int mNumberOfDays = 30;
	Date mStartDate;
	PackageBy mPackageBy = PackageBy.day;
	string mSaveToFolder;
	SaveToCalibre mSaveToCalibre = SaveToCalibre.yes;
	string mStartDateString;

	Date toDate(string input)
	{
		import std.range;
		
		int year, month, day;
		
		foreach(i, field; input.splitter("-").take(3).array)
		{
			switch (i)
			{
				case 0:
					year = field.forceToInt;
					break;
					
				case 1:
					month = field.forceToInt;
					
					if (month==0)
					{
						month = field.forceMonthToInt;
					}
					
					break;
					
				case 2:
					day = field.forceToInt;
					break;
					
				default:
					break;
			}
		}
		
		if (year==0 || month==0 || day == 0)
		{
			return mStartDate;
		}
		else
		{
			return Date(year, month, day);
		}
	}
}

private Date today()
{
	return cast(Date)Clock.currTime;
}

private Date tomorrow()
{
	return cast(Date)Clock.currTime + dur!"days"(1);
}

private string baseName(string fullName)
{
	import std.algorithm;
	return fullName.splitter(".").back.splitter("(").front;
}

private int forceToInt(string input)
{
	import std.conv;

	int result;

	try
	{
		result = input.to!int;
	}
	catch
	{
		result = 0;
	}

	return result;
}

private int forceMonthToInt(string input)
{
	import std.conv;
	import std.uni;
	import std.utf;

	int result;

	try
	{
		result = input.trim.asLowerCase.array.to!Month.to!int;
	}
	catch {}

	return result;
}


private string trim(string input)
{
	import std.regex;

	auto match = input.matchFirst(`^\s*`);

	string result;

	if (!match.empty)
	{
		result = match.post;
	}

	match = result.matchFirst(`\s*$`);

	if (!match.empty)
	{
		result = match.pre;
	}

	return result;
}