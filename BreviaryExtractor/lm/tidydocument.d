module lm.tidydocument;

private import std.algorithm.iteration;
private import std.conv;
private import std.string;
private import std.traits;
private import std.typecons;

private import lm.tidyinterface;

enum TidyCharEncoding
{
	raw = "raw",
	ascii = "ascii",
	latin0 = "latin0",
	latin1 = "latin1",
	utf8 = "utf8",
	iso2022 = "iso2022",
	mac = "mac",
	win1252 = "win1252",
	ibm858 = "ibm858",
	utf16le = "utf16le",
	utf16be = "utf16be",
	utf16 = "utf16",
	big5 = "big5",
	shiftjis = "shiftjis"
}

enum TidyNewline
{
	LF = "LF", CRLF = "CRLF", CR = "CR"
}

enum TidyDoctype
{
	html5 = "html5",
	omit = "omit",
	automatic = "auto",
	strict = "strict",
	transitional = "transitional",
	user = "user"
}

enum TidyDuplicateAttrs
{
	keepFirst = "keep-first",
	keepLast = "keep-last"
}

enum TidyAutoBool
{
	yes = "yes",
	no = "no",
	automatic = "auto"
}

enum TidyBool
{
	yes = "yes",
	no = "no"
}

/**
 * A convenience function to clean up HTML quickly without
 * a lot of configuration.
 */
R cleanHtml(R)(R input)
	if (isSomeString!R)
{
	
	static if(is(R==string))
	{
		auto tidyDocument = TidyDocument(input);
		return tidyDocument.output;
	}
	else
	{
		auto tidyDocument = TidyDocument(input.idup);
		return tidyDocument.output.dup;
	}
}

struct TidyDocument
{
	this(string input)
	{
		this.input = input;
		
		// 1. Initialize Tidy document.
		tidyDoc = tidyCreate();
		
		// 2. Set up an output buffer.
		tidyBufInit(&outputBuffer);
		
		// We will set the tidy options when we are ready to do a printout
	}
	
	~this()
	{
		// Release the TidyDoc object and the output buffer.
		tidyBufFree(&outputBuffer);
		tidyRelease(tidyDoc);
	}
	
	immutable string input;
	
	@property string output()
	{
		// Reset everything to the default settings and apply the correct settings.
		tidyOptResetAllToDefault(tidyDoc);
		setTidyOptions();
		
		errorCode = tidyParseString(tidyDoc, input.toStringz);
		
		if (errorCode >=0)
		{
			errorCode = tidyCleanAndRepair(tidyDoc);
		}
		
		if (errorCode >=0)
		{
			errorCode = tidySaveBuffer(tidyDoc, &outputBuffer);
			bufferWasUsed = true;
		}
		
		if (errorCode < 0)
		{
			throw new Exception ("A severe error occured in libtidy.");
		}
		
		assert (outputBuffer.bp != null, "The Tidy output buffer returned a null pointer.");
		
		return (cast(char*)outputBuffer.bp).to!string;
	}
	
	// The properties. I will select a reduced number for convenience.
	
	version(all)
	{
		int indentSpaces = 2;
		int wrapLen =  68;
		int tabSize =  8;
		TidyCharEncoding charEncoding =  TidyCharEncoding.utf8;
		TidyCharEncoding inCharEncoding =  TidyCharEncoding.utf8;
		TidyCharEncoding outCharEncoding =  TidyCharEncoding.utf8;
		version(Windows)
		{
			TidyNewline newline = TidyNewline.CRLF;
		}
		else
		{
			TidyNewline newline = TidyNewline.LF;
		}
		bool quiet =  true;
		TidyAutoBool indentContent =  TidyAutoBool.no;
		bool showWarnings =  false;
		bool numEntities =  false;
		bool mark = false;
	}
	
	version(LeftAsDefault)
	{
		TidyDoctype doctypeMode = TidyDoctype.automatic;
		string doctype = "";
		TidyDuplicateAttrs duplicateAttrs = TidyDuplicateAttrs.keepLast;
		string altText = "";
		//string slideStyle = "";
		string errFile = "";
		string outFile = "";
		bool writeBack = false;
		bool showMarkup = true;
		bool showInfo = true;
		bool coerceEndTags = true;
		bool omitOptionalTags = false;
		bool hideEndTags = true;
		bool xmlTags = true;
		bool xmlOut = true;
		bool xhtmlOut = true;
		bool htmlOut = true;
		bool xmlDecl = true;
		bool upperCaseTags = true;
		bool upperCaseAttrs = true;
		bool makeBare = true;
		bool makeClean = true;
		bool gDocClean = true;
		bool logicalEmphasis = true;
		bool dropPropAttrs = true;
		bool dropFontTags = true;
		bool dropEmptyElems = true;
		bool dropEmptyParas = true;
		bool fixComments = true;
		bool breakBeforeBR = true;
		bool burstSlides = true;
		bool quoteMarks = true;
		bool quoteNbsp = true;
		bool quoteAmpersand = true;
		bool wrapAttVals = true;
		bool wrapScriptlets = true;
		bool wrapSection = true;
		bool wrapAsp = true;
		bool wrapJste = true;
		bool wrapPhp = true;
		bool fixBackslash = true;
		bool indentAttributes = true;
		bool xmlPIs = true;
		bool xmlSpace = true;
		bool encloseBodyText = true;
		bool encloseBlockText = true;
		bool keepFileTimes = true;
		bool word2000 = true;
		bool emacs = true;
		bool emacsFile = true;
		bool literalAttribs = true;
		bool bodyOnly = true;
		bool fixUri = true;
		bool lowerLiterals = true;
		bool hideComments = true;
		bool indentCdata = true;
		bool forceOutput = true;
		bool showErrors = true;
		bool asciiChars = true;
		bool joinClasses = true;
		bool joinStyles = true;
		bool escapeCdata = true;
		bool language = true;
		bool ncr = true;
		bool outputBOM = true;
		bool replaceColor = true;
		bool cssPrefix = true;
		bool inlineTags = true;
		bool blockTags = true;
		bool emptyTags = true;
		bool preTags = true;
		bool accessibilityCheckLevel = true;
		bool vertSpace = true;
		bool punctWrap = true;
		bool mergeEmphasis = true;
		bool mergeDivs = true;
		bool decorateInferredUL = true;
		bool preserveEntities = true;
		bool sortAttributes = true;
		bool mergeSpans = true;
		bool anchorAsName = true;	
	}
	
private:
	
	bool bufferWasUsed = false;
	
	void setTidyOptions()
	{
		foreach(i, val; defaults.tupleof)
		{
			// The defaults and the TidyProperties are always kept in the same order, so it is safe to look them up:
			auto tidyProperty = tidyProperties.tupleof[i];
			
			// The following mixin cleverly reads the Tidy option that needs to be dealt with right now.
			mixin ("auto currentTidyOption = " ~ defaults.tupleof[i].stringof.lastMember ~ ";");
			
			// Right now, this simply sets all of the available options.
			// I might have it not do anything if the setting happens to be a default setting.
			static if(isBoolean!(typeof(val)))
			{
				optionSetIsOK = optionSetIsOK & tidyOptSetBool(tidyDoc, tidyProperty, cast(Bool)currentTidyOption);
			}
			else static if(isIntegral!(typeof(val)))
			{
				optionSetIsOK = optionSetIsOK & tidyOptSetInt(tidyDoc, tidyProperty, currentTidyOption);
			}
			else // it will be one of the enums.
			{
				optionSetIsOK = optionSetIsOK & tidyOptSetValue(tidyDoc, tidyProperty, (cast(string)currentTidyOption).toStringz);
			}
			
			if (!optionSetIsOK)
			{
				throw new Exception ("One of the tidy options didn't work.");
			}
		}
	}
	
	TidyBuffer outputBuffer;
	int errorCode = -1;
	TidyDoc tidyDoc;
	bool optionSetIsOK = true;
	
}

private struct Defaults
{
	int indentSpaces;
	int wrapLen;
	int tabSize;
	TidyCharEncoding charEncoding;
	TidyCharEncoding inCharEncoding;
	TidyCharEncoding outCharEncoding;
	TidyNewline newline;
	bool quiet;
	TidyAutoBool indentContent;
	bool showWarnings;
	bool numEntities;
	bool mark;
}

version(windows) {
	immutable newlineDefault = TidyNewline.CRLF;
}
else
{
	immutable newlineDefault = TidyNewline.LF;
}

private struct TidyProperties
{
	TidyOptionId indentSpaces;
	TidyOptionId wrapLen;
	TidyOptionId tabSize;
	TidyOptionId charEncoding;
	TidyOptionId inCharEncoding;
	TidyOptionId outCharEncoding;
	TidyOptionId newline;
	TidyOptionId quiet;
	TidyOptionId indentContent;
	TidyOptionId showWarnings;
	TidyOptionId numEntities;
	TidyOptionId mark;
}

private immutable tidyProperties = TidyProperties (
	TidyOptionId.TidyIndentSpaces,
	TidyOptionId.TidyWrapLen,
	TidyOptionId.TidyTabSize,
	TidyOptionId.TidyCharEncoding,
	TidyOptionId.TidyInCharEncoding,
	TidyOptionId.TidyOutCharEncoding,
	TidyOptionId.TidyNewline,
	TidyOptionId.TidyQuiet,
	TidyOptionId.TidyIndentContent,
	TidyOptionId.TidyShowWarnings,
	TidyOptionId.TidyNumEntities,
	TidyOptionId.TidyMark);

private immutable defaults = Defaults(
	2,
	68,
	8,
	TidyCharEncoding.utf8,
	TidyCharEncoding.utf8,
	TidyCharEncoding.utf8,
	newlineDefault,
	false,
	TidyAutoBool.no,
	true,
	false,
	true);

private string lastMember(string input)
{
	auto parts = input.splitter(".");
	if (parts.empty)
	{
		return "";
	}
	else
	{
		return parts.back;
	}
}

private int tidyTest()
{
	import std.stdio;
	
	string input = "<title>Foo</title><p>Foo!";
	
	TidyBuffer output;
	TidyBuffer errbuf;
	
	int rc = -1;
	
	TidyDoc tdoc = tidyCreate();                     // Initialize document
	tidyBufInit( &output );
	tidyBufInit( &errbuf );
	
	scope(exit)
	{
		tidyBufFree( &output );
		tidyBufFree( &errbuf );
		tidyRelease( tdoc );
	}
	
	writefln("Tidying:\t%s\n", input );
	auto ok = tidyOptSetBool( tdoc, TidyOptionId.TidyXhtmlOut, Bool.yes );  // Convert to XHTML
	
	if ( ok )
	{
		rc = tidySetErrorBuffer( tdoc, &errbuf );      // Capture diagnostics
	}
	if ( rc >= 0 )
	{
		rc = tidyParseString( tdoc, input.toStringz ); // Parse the input
	}
	if ( rc >= 0 )
	{
		rc = tidyCleanAndRepair( tdoc );               // Tidy it up!
	}
	if ( rc >= 0 )
	{
		rc = tidyRunDiagnostics( tdoc );               // Find any errors.
	}
	if ( rc > 1 )                                      // If error, force output.
	{
		rc = ( tidyOptSetBool(tdoc, TidyOptionId.TidyForceOutput, Bool.yes) ? rc : -1 );
	}
	if ( rc >= 0 )
	{
		rc = tidySaveBuffer( tdoc, &output );          // Pretty Print
	}
	if ( rc >= 0 )
	{
		if ( rc > 0 )
		{
			writef( "\nDiagnostics:\n\n%s", (cast(char*)errbuf.bp).to!string );
		}
		writef( "\nAnd here is the result:\n\n%s", (cast(char*)output.bp).to!string );
	}
	else
	{
		writefln( "A severe error (%d) occurred.", rc );
	}
	
	return rc;
}

//R cleanHtml(R)(R input)
//	if (isSomeString!R)
//{
//	string html = input;
//	
//	auto tidyDoc = tidyCreate();
//	TidyBuffer tidyOutputBuffer;
//
//	scope(exit)
//	{
//		// Free the memory.
//		tidyBufFree(&tidyOutputBuffer);
//		tidyRelease(tidyDoc);
//	}
//
//	// Configure Tidy
//	// The flags tell Tidy to disable showing warnings
//	auto configSuccess = // tidyOptSetBool(tidyDoc, TidyOptionId.TidyXmlOut, Bool.yes)
//		tidyOptSetBool(tidyDoc, TidyOptionId.TidyQuiet, Bool.yes) &&
//			tidyOptSetValue(tidyDoc, TidyOptionId.TidyIndentContent, "auto") &&
//			tidyOptSetBool(tidyDoc, TidyOptionId.TidyNumEntities, Bool.yes) &&
//			tidyOptSetBool(tidyDoc, TidyOptionId.TidyShowWarnings, Bool.no) &&
//			tidyOptSetValue(tidyDoc, TidyOptionId.TidyCharEncoding, "utf8") &&
//			tidyOptSetInt(tidyDoc, TidyOptionId.TidyWrapLen, 0);
//	
//	int tidyResponseCode = -1;
//	
//
//	// Parse input
//	if (configSuccess)
//	{
//		tidyResponseCode = tidyParseString(tidyDoc, html.toStringz);
//	}
//
//	// Process HTML
//	if (tidyResponseCode >= 0)
//	{
//		tidyResponseCode = tidyCleanAndRepair(tidyDoc);
//
//		// Output the HTML to our buffer
//		if (tidyResponseCode >= 0)
//		{
//			tidyResponseCode = tidySaveBuffer(tidyDoc, &tidyOutputBuffer);
//		}
//	}
//	else //tidyResponseCode < 0 means there are errors from Tidy.
//	{
//		// throw (Tidy encountered an error while parsing an HTML response. Tidy response code:  + tidyResponseCode);
//	}
//
//	// Grab the result from the buffer and then free Tidy's memory
//	string result = (cast(char*)tidyOutputBuffer.bp).to!string;
//
//	return result;
//}

