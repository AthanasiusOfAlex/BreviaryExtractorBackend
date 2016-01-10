module lm.regexhelper;

public import std.regex;
import std.traits;

/**
 * Returns true if the regex 're' matches 'input'.
 * For example,
 *    "Star-spangled banner".isMatchOf("ban+er");
 * returns true.
 */
bool isMatchOf(R, Rgx)(R input, Rgx re)
	if (isSomeString!R && (is(Rgx==Regex!char) || is(Rgx==StaticRegex!char) || isSomeString!Rgx))
{
	static if (is(Rgx==Regex!char) || is(Rgx==StaticRegex!char))
	{
		auto rgx = re;
	}
	else
	{
		auto rgx = regex(re, "s");
	}
	return !matchFirst(input, rgx).empty;
}

/**
 * Returns true if the regex 're' matches 'input'.
 * Uses compile-time arguments.
 * For example,
 *    isMatchOf!("Star-spangled banner", "ban+er");
 * returns true.
 */
bool isMatchOf(string input, string rgx)()
{
	return !matchFirst(input, ctRegex!(rgx, "s")).empty;
}

/**
 * Takes one compile-time and one run-time argument.
 * (The second compile-time argument, 'R', is deduced.)
 * Returns true if the compile-time argument, 'rgx',
 * matches the run-time argument, 'input'. For example:
 * "Star-spangled banner".isMatchOf!"ban+er"
 * returns true. It is suggested to use the function in
 * this form, although
 * isMatchOf!"ban+er"("Star-spangled banner");
 * will also return true.
 */
bool isMatchOf(string rgx, R)(R input)
	if(isSomeString!R)
{
	return !matchFirst(input, ctRegex!(rgx, "s")).empty;
}

/**
 * Simply replaces the regex 're' with 'replacement'
 * in the string 'input'. For example,
 * "Star Spangled".simpleReplaceAll("a[rn]", "**");
 * will return "St** Sp**gled".
 */
R simpleReplaceAll(R, S, T)(R input, S re, T replacement)
	if (isSomeString!R && (is(S==Regex!char) || is(S==StaticRegex!char) || isSomeString!S) && isSomeString!T)
{
	static if (is(S==Regex!char) || is(S==StaticRegex!char))
	{
		return replaceAll(input, re, replacement);
	}
	else
	{
		return replaceAll(input, regex(re, "s"), replacement);
	}
}

/**
 * Simply replaces the regex 're' with 'replacement'
 * in the string 'input'. This version is used when
 * the regex is already known at complie time. For
 * example,
 * "Star Spangled".simpleReplaceAll!"a[rn]"("**");
 * will return "St** Sp**gled".
 */
R simpleReplaceAll(string Re, R, T)(R input, T replacement)
	if (isSomeString!R && isSomeString!T)
{
	return replaceAll(input, ctRegex!(Re, "s"), replacement);
}

/**
 * Simply replaces the regex 're' with 'replacement'
 * in the string 'input'. This version is used when
 * both regex and replacement are known at
 * complie time. For example,
 * "Star Spangled".simpleReplaceAll!("a[rn]", "**");
 * will return "St** Sp**gled".
 */
R simpleReplaceAll(string Re, string replacement, R)(R input)
	if (isSomeString!R)
{
	return replaceAll(input, ctRegex!(Re, "s"), replacement);
}

R[] splitFirst(R, S)(R input, S delimiter)
	if (isSomeString!R && (is(S==Regex!char) || is(S==StaticRegex!char) || isSomeString!S))
{
	static if (is(S==Regex!char) || is(S==StaticRegex!char))
	{
		auto delimeterRegex = delimiter;
	}
	else
	{
		auto delimeterRegex = regex(delimiter);
	}

	auto captures = matchFirst(input, delimeterRegex);

	if (!captures.empty)
	{
		return [captures.pre, captures.post];
	}
	else
	{
		return [input];
	}
}