module helperfunctions;

import std.regex;
import std.traits;

private uint convertCodeToInt(R)(R code)
	if(isSomeString!R)
{
	uint result;
	auto m = matchFirst(code, "[0-9]+");
	
	if (m.empty) 
	{
		result = 0;
	}
	else
	{
		import std.conv;
		result = m.hit.to!uint;
	}
	
	return result;
}

private R convertIntToUnicodeCharacter(R)(uint code)
	if(isSomeString!R)
{
	import std.utf;

	char[] working_string;
	encode(working_string, code);
	
	return working_string.dup;
}

private R convertCodeToUnicodeCharacter(R)(R code)
	if(isSomeString!R)
{
	uint intCode = convertCodeToInt(code);
	
	R result;
	
	if (intCode>0)		// I don't want any null characters getting in. Just remove them altogether.
	{
		result = convertIntToUnicodeCharacter!R(intCode);
	}
	
	return result;
}

R replaceEntitiesWithUnicode(R)(R input)
	if(isSomeString!R)
{
	auto m = matchAll(input, "&#[0-9]+;");
	
	// Get a list of things to match.
	UniqueArray!string listOfMatches;
	foreach (c; m)
	{
		listOfMatches ~= c.hit.idup;
	}
	
	// Replace 'em!
	char[] working_text = input.dup;
	foreach (c; listOfMatches.baseArray)
	{
		working_text = replaceAll(working_text, regex(c), convertCodeToUnicodeCharacter(c));
	}

	return working_text.dup;
}

R simpleHtmlToLatex(R)(R input, R html_tag, R latex_tag)
{
	char[] working_text = simpleReplaceAll(input.dup, "<" ~ html_tag ~ ">", "\\" ~ latex_tag ~ "{");
	working_text = simpleReplaceAll(working_text, "</" ~ html_tag ~ ">", "}");
	return working_text.dup;
}

R simpleExtract(R, S)(R input, S re, string key="")
	if (isSomeString!R && (is(S==Regex!char) || is(S==StaticRegex!char) || isSomeString!S))
{
	static if (is(S==Regex!char) || is(S==StaticRegex!char))
	{
		auto c = matchFirst(input, re);
	}
	else
	{
		auto c = matchFirst(input, regex(re, "s"));
	}
	
	R result;
	if(c.empty)
	{
		result = "".dup;
	}
	else
	{
		if (key=="")
		{
			result = c.hit;
		}
		else
		{
			try
			{
				result = c[key];
			}
			catch // I don't really care what the error is. It will return ""
			{
				result = "".dup;
			}
		}
	}
	return result;
}

R removeExtraWhiteSpace(R)(in R text)
{
	// Replace any contiguous white space with a single space.
	char[] working_text = simpleReplaceAll(text.dup, "\\s+", " ");
	
	// Remove any spaces before and after <br />.
	working_text = simpleReplaceAll(working_text, "\\s+<br />\\s+", "<br />");
	
	// Replace double <br /> with <p> (preceded by newline).
	working_text = simpleReplaceAll(working_text, "<br /><br />", "\n<p>");
	
	// Reinstate newlines after each <br />
	working_text = simpleReplaceAll(working_text, "<br />", "<br />\n");
	
	// Remove any final white space left.
	working_text = simpleReplaceAll(working_text, "\\s+$", "");
	
	return working_text.dup;
}

R cleanUpPsalm(R)(in R input)
{
	char[] working_text;
	
	working_text ~= simpleReplaceAll(input, "\\s*(<br />\\s*){2,}", "\n\n\\newstanza\n\n");
	working_text = simpleReplaceAll(working_text,
	                                  "\\s*<span\\s+class=\\s*\"rubrica\">\\*</span><br />\\s*",
	                                  "\\caesura\n");
	working_text = simpleReplaceAll(working_text,
	                                  "\\s*<span\\s+class=\\s*\"rubrica\">†</span><br />\\s*",
	                                  "\\flexa\n");
	working_text = simpleReplaceAll(working_text, "\\s*<br />\\s*", "\\newlyricline\n");
	
	R result = working_text.dup;
	return result;
}

R stripLinebreaksAndParagraphs(R)(in R input)
    if(isSomeString!R)
{
    return simpleReplaceAll(input, ctRegex!(r"[\r\n]", "s"), " ");
}

R stripDuplicatedWhitespace(R)(in R input)
    if(isSomeString!R)
{
    return simpleReplaceAll(input, ctRegex!(r"\s+", "s"), " ");
}


/**
 * Holds the maximum value.
 * Use the left bit-shift operator 
 * to enter a new value.
 */
struct MaxTracker(R)
	if(isNumeric!R)
{
public:
	R max;
	
	ref MaxTracker opBinary(string op)(in R rhs)
		if (op == "<<")
	{
		if(rhs > max) { max = rhs; }
		return this;
	}
}

struct UniqueArray(R)
{
	import std.algorithm;
	
public:
	void append(R  new_match) {
		if (!m_baseArray.canFind(new_match))
		{
			m_baseArray ~= new_match.dup;
		}
	}
	
	ref UniqueArray opOpAssign(R op)(in R new_match)
		if (op == "~")
	{
		append(new_match);
		return this;
	}
	
	
	ref UniqueArray opOpAssign(R op)(in R[] new_match)
		if (op == "~")
	{
		foreach(i; new_match)
		{
			append(i);
		}
		return this;
	}
	
	@property auto baseArray() { return m_baseArray; }
	
protected:
	R[] m_baseArray;
};

/**
 * Prints "UpTo" n characters of a string.
 */
string upTo(string input, uint n)
{
    import std.algorithm;
    import std.uni;
    import std.utf;
    
    dstring working = input.normalize.toUTF32;  // Just make sure there are no unicode problems.
    
    return working[0 .. min(n, $)].toUTF8;
}