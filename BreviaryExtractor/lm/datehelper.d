module lm.datehelper;

import std.datetime;

string toLongDate(Date date)
{
	import std.conv;
	
	string[int] longMonthName = [
		Month.jan : "January",
		Month.feb : "February",
		Month.mar : "March",
		Month.apr : "April",
		Month.may : "May",
		Month.jun : "June",
		Month.jul : "July",
		Month.aug : "August",
		Month.sep : "September",
		Month.oct : "October",
		Month.nov : "November",
		Month.dec : "December"
	];
	
	return longMonthName[date.month] ~ " " ~ date.day.to!string() ~ ", " ~ date.year.to!string;
}

/**
 * Returns an anonymous range that returns a string of dates,
 * starting with the date given as an argument (by default,
 * today).
 */
auto dateGenerator(Date date = cast(Date)Clock.currTime)
{
	struct dateMachine
	{
		@property Date front()
		{
			return date;
		}
		
		@property bool empty()
		{
			return false;
		}
		
		void popFront()
		{
			date += dur!"days"(1);
		}
	}
	
	dateMachine machine;
	return machine;
}