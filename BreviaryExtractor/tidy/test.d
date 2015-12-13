module libtidy.test;

import libtidy.tidy;
import libtidy.buffio;
import std.c.stdio;
import std.stdio;
import std.string;
import std.conv;

int test(string[] args)
{
	const char* input = `<title>Foo</title><p>Foo!`;
	TidyBuffer output;
	TidyBuffer errbuf;
	int rc = -1;

	TidyDoc tdoc = tidyCreate();                     // Initialize "document"
	tidyBufInit(&output);
	tidyBufInit(&errbuf);
	writefln("Tidying:\t%s\n", input.to!string);

	auto OK2 = tidyOptSetValue(tdoc, TidyOptionId.TidyIndentContent, "auto");
	auto OK = tidyOptSetBool(tdoc, TidyOptionId.TidyQuiet, Bool.yes);
//	auto OK = tidyOptSetBool(tdoc, TidyOptionId.TidyQuiet, Bool.yes) &&
//		tidyOptSetValue(tdoc, TidyOptionId.TidyIndentContent, "auto") &&
//			tidyOptSetBool(tdoc, TidyOptionId.TidyNumEntities, Bool.yes) &&
//			tidyOptSetBool(tdoc, TidyOptionId.TidyShowWarnings, Bool.no) &&
//			tidyOptSetValue(tdoc, TidyOptionId.TidyCharEncoding, "utf8") &&
//			tidyOptSetInt(tdoc, TidyOptionId.TidyWrapLen, 0);
	auto ok = OK ? Bool.yes : Bool.no;

	//ok = tidyOptSetBool(tdoc, TidyOptionId.TidyXhtmlOut, Bool.yes );  // Convert to XHTML
	if (ok)
	{
		rc = tidySetErrorBuffer(tdoc, &errbuf);       // Capture diagnostics
	}
	if (rc >= 0)
	{
		rc = tidyParseString(tdoc, input);            // Parse the input
	}
	if (rc >= 0)
	{
		rc = tidyCleanAndRepair(tdoc);                // Tidy it up!
	}
  	if (rc >= 0)
	{
		rc = tidyRunDiagnostics(tdoc);                // Kvetch
	}
	if (rc > 1)                                       // If error, force output.
	{
		rc = (tidyOptSetBool(tdoc, TidyOptionId.TidyForceOutput, Bool.yes) ? rc : -1 );
	}
	if (rc >= 0)
	{
		rc = tidySaveBuffer(tdoc, &output);           // Pretty Print
	}

	if (rc >= 0)
	{
		if (rc > 0)
		{
			writefln("\nDiagnostics:\n\n%s", output.bp.fromTidyBuffer);
		}
		writefln("\nAnd here is the result:\n\n%s", output.bp.fromTidyBuffer);
	}
	else
	{
		writefln("A severe error (%d) occurred.\n", rc);
	}
  tidyBufFree(&output );
  tidyBufFree(&errbuf );
  tidyRelease(tdoc );
  return rc;
}

private pure nothrow inout(char)[] fromTidyBuffer(inout(byte)* buffer)
{
	return fromStringz(cast(char*)(buffer));
}