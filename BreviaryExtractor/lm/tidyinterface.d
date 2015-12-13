module lm.tidyinterface;

pragma(lib, "tidys");

import std.conv;
import std.string;
import std.traits;

private:

// I am just copying in manually the parts of the API from Tidy that I need.
// The only thing I need it to do is re-arrange the code into nice, tidy(!) HTML.

struct _TidyDoc
{
	int _opaque;
};

alias TidyDoc = const _TidyDoc *;

struct _TidyBuffer 
{
	TidyAllocator* allocator; 	 /**< Memory allocator */
	ubyte* bp;           		/**< Pointer to bytes */
	uint  size;         /**< # bytes currently in use */
	uint  allocated;    /**< # bytes allocated */ 
	uint  next;         /**< Offset of current input position */
};

alias TidyBuffer = _TidyBuffer;

struct _TidyAllocator {
	const TidyAllocatorVtbl *vtbl;
};
alias TidyAllocator = _TidyAllocator;

struct _TidyAllocatorVtbl {
	/** Called to allocate a block of nBytes of memory */
	void* function( TidyAllocator *self, size_t nBytes ) alloc;
	/** Called to resize (grow, in general) a block of memory.
	 Must support being called with NULL.
	 */
	void* function( TidyAllocator *self, void *block, size_t nBytes ) realloc;
	/** Called to free a previously allocated block of memory */
	void function( TidyAllocator *self, void *block) free;
	/** Called when a panic condition is detected.  Must support
	 block == NULL.  This function is not called if either alloc 
	 or realloc fails; it is up to the allocator to do this.
	 Currently this function can only be called if an error is
	 detected in the tree integrity via the internal function
	 CheckNodeIntegrity().  This is a situation that can
	 only arise in the case of a programming error in tidylib.
	 You can turn off node integrity checking by defining
	 the constant NO_NODE_INTEGRITY_CHECK during the build.
	 **/
	void function( TidyAllocator *self, ctmbstr msg ) panic;
};

alias TidyAllocatorVtbl = _TidyAllocatorVtbl;

alias tchar = uint;              /* single, full character */
alias tmbchar = char ;           /* single, possibly partial character */
alias tmbstr = tmbchar* ;        /* pointer to buffer of possibly partial chars */
alias ctmbstr = const tmbchar* ; /* Ditto, but const */

enum Bool
{
	no,
	yes
};

/** Categories of Tidy configuration options
 */
enum TidyConfigCategory
{
	TidyMarkup,          /**< Markup options: (X)HTML version, etc */
	TidyDiagnostics,     /**< Diagnostics */
	TidyPrettyPrint,     /**< Output layout */
	TidyEncoding,        /**< Character encodings */
	TidyMiscellaneous    /**< File handling, message format, etc. */
}

/** Option IDs Used to get/set option values.
 */
enum TidyOptionId
{
	TidyUnknownOption,   /**< Unknown option! */
	TidyIndentSpaces,    /**< Indentation n spaces */
	TidyWrapLen,         /**< Wrap margin */
	TidyTabSize,         /**< Expand tabs to n spaces */
	
	TidyCharEncoding,    /**< In/out character encoding */
	TidyInCharEncoding,  /**< Input character encoding (if different) */
	TidyOutCharEncoding, /**< Output character encoding (if different) */    
	TidyNewline,         /**< Output line ending (default to platform) */
	
	TidyDoctypeMode,     /**< See doctype property */
	TidyDoctype,         /**< User specified doctype */
	
	TidyDuplicateAttrs,  /**< Keep first or last duplicate attribute */
	TidyAltText,         /**< Default text for alt attribute */

	/* obsolete */
	TidySlideStyle,      /**< Style sheet for slides: not used for anything yet */
	
	TidyErrFile,         /**< File name to write errors to */
	TidyOutFile,         /**< File name to write markup to */
	TidyWriteBack,       /**< If true then output tidied markup */
	TidyShowMarkup,      /**< If false, normal output is suppressed */
	TidyShowInfo,        /**< If true, info-level messages are shown */
	TidyShowWarnings,    /**< However errors are always shown */
	TidyQuiet,           /**< No 'Parsing X', guessed DTD or summary */
	TidyIndentContent,   /**< Indent content of appropriate tags */
	/**< "auto" does text/block level content indentation */
	TidyCoerceEndTags,   /**< Coerce end tags from start tags where probably intended */
	TidyOmitOptionalTags,/**< Suppress optional start tags and end tags */
	TidyHideEndTags,     /**< Legacy name for TidyOmitOptionalTags */
	TidyXmlTags,         /**< Treat input as XML */
	TidyXmlOut,          /**< Create output as XML */
	TidyXhtmlOut,        /**< Output extensible HTML */
	TidyHtmlOut,         /**< Output plain HTML, even for XHTML input.
	                      Yes means set explicitly. */
	TidyXmlDecl,         /**< Add <?xml?> for XML docs */
	TidyUpperCaseTags,   /**< Output tags in upper not lower case */
	TidyUpperCaseAttrs,  /**< Output attributes in upper not lower case */
	TidyMakeBare,        /**< Make bare HTML: remove Microsoft cruft */
	TidyMakeClean,       /**< Replace presentational clutter by style rules */
	TidyGDocClean,       /**< Clean up HTML exported from Google Docs */
	TidyLogicalEmphasis, /**< Replace i by em and b by strong */
	TidyDropPropAttrs,   /**< Discard proprietary attributes */
	TidyDropFontTags,    /**< Discard presentation tags */
	TidyDropEmptyElems,  /**< Discard empty elements */
	TidyDropEmptyParas,  /**< Discard empty p elements */
	TidyFixComments,     /**< Fix comments with adjacent hyphens */
	TidyBreakBeforeBR,   /**< Output newline before <br> or not? */
	
	/* obsolete */
	TidyBurstSlides,     /**< Create slides on each h2 element */
	
	TidyNumEntities,     /**< Use numeric entities */
	TidyQuoteMarks,      /**< Output " marks as &quot; */
	TidyQuoteNbsp,       /**< Output non-breaking space as entity */
	TidyQuoteAmpersand,  /**< Output naked ampersand as &amp; */
	TidyWrapAttVals,     /**< Wrap within attribute values */
	TidyWrapScriptlets,  /**< Wrap within JavaScript string literals */
	TidyWrapSection,     /**< Wrap within <![ ... ]> section tags */
	TidyWrapAsp,         /**< Wrap within ASP pseudo elements */
	TidyWrapJste,        /**< Wrap within JSTE pseudo elements */
	TidyWrapPhp,         /**< Wrap within PHP pseudo elements */
	TidyFixBackslash,    /**< Fix URLs by replacing \ with / */
	TidyIndentAttributes,/**< Newline+indent before each attribute */
	TidyXmlPIs,          /**< If set to yes PIs must end with ?> */
	TidyXmlSpace,        /**< If set to yes adds xml:space attr as needed */
	TidyEncloseBodyText, /**< If yes text at body is wrapped in P's */
	TidyEncloseBlockText,/**< If yes text in blocks is wrapped in P's */
	TidyKeepFileTimes,   /**< If yes last modied time is preserved */
	TidyWord2000,        /**< Draconian cleaning for Word2000 */
	TidyMark,            /**< Add meta element indicating tidied doc */
	TidyEmacs,           /**< If true format error output for GNU Emacs */
	TidyEmacsFile,       /**< Name of current Emacs file */
	TidyLiteralAttribs,  /**< If true attributes may use newlines */
	TidyBodyOnly,        /**< Output BODY content only */
	TidyFixUri,          /**< Applies URI encoding if necessary */
	TidyLowerLiterals,   /**< Folds known attribute values to lower case */
	TidyHideComments,    /**< Hides all (real) comments in output */
	TidyIndentCdata,     /**< Indent <!CDATA[ ... ]]> section */
	TidyForceOutput,     /**< Output document even if errors were found */
	TidyShowErrors,      /**< Number of errors to put out */
	TidyAsciiChars,      /**< Convert quotes and dashes to nearest ASCII char */
	TidyJoinClasses,     /**< Join multiple class attributes */
	TidyJoinStyles,      /**< Join multiple style attributes */
	TidyEscapeCdata,     /**< Replace <![CDATA[]]> sections with escaped text */
	
	//#if SUPPORT_ASIAN_ENCODINGS
	TidyLanguage,        /**< Language property: not used for anything yet */
	TidyNCR,             /**< Allow numeric character references */
	//#else
	//    TidyLanguageNotUsed,
	//    TidyNCRNotUsed,
	//#endif
	//#if SUPPORT_UTF16_ENCODINGS
	TidyOutputBOM,      /**< Output a Byte Order Mark (BOM) for UTF-16 encodings */
	/**< auto: if input stream has BOM, we output a BOM */
	//#else
	//    TidyOutputBOMNotUsed,
	//#endif
	
	TidyReplaceColor,    /**< Replace hex color attribute values with names */
	TidyCSSPrefix,       /**< CSS class naming for -clean option */
	
	TidyInlineTags,      /**< Declared inline tags */
	TidyBlockTags,       /**< Declared block tags */
	TidyEmptyTags,       /**< Declared empty tags */
	TidyPreTags,         /**< Declared pre tags */
	
	TidyAccessibilityCheckLevel, /**< Accessibility check level 
	                              0 (old style), or 1, 2, 3 */
	
	TidyVertSpace,       /**< degree to which markup is spread out vertically */
	//#if SUPPORT_ASIAN_ENCODINGS
	TidyPunctWrap,       /**< consider punctuation and breaking spaces for wrapping */
	//#else
	//    TidyPunctWrapNotUsed,
	//#endif
	TidyMergeEmphasis,       /**< Merge nested B and I elements */
	TidyMergeDivs,       /**< Merge multiple DIVs */
	TidyDecorateInferredUL,  /**< Mark inferred UL elements with no indent CSS */
	TidyPreserveEntities,    /**< Preserve entities */
	TidySortAttributes,      /**< Sort attributes */
	TidyMergeSpans,       /**< Merge multiple SPANs */
	TidyAnchorAsName //,    /**< Define anchors as name attributes */
	//    N_TIDY_OPTIONS       /**< Must be last */
};


extern (C) TidyDoc tidyCreate();
extern (C) void tidyBufInit( TidyBuffer* buf );
extern (C) void tidyBufFree( TidyBuffer* buf );
extern (C) void tidyRelease( TidyDoc tdoc );
extern (C) Bool tidyOptSetBool ( TidyDoc tdoc, TidyOptionId optId, Bool val );
extern (C) Bool tidyOptSetValue( TidyDoc tdoc, TidyOptionId optId, ctmbstr val );
extern (C) Bool tidyOptSetInt( TidyDoc tdoc, TidyOptionId optId, ulong val );
extern (C) int tidyParseString( TidyDoc tdoc, ctmbstr content );
extern (C) int tidyCleanAndRepair( TidyDoc tdoc );
extern (C) int tidySaveBuffer( TidyDoc tdoc, TidyBuffer* buf );
extern (C) int tidySetErrorBuffer( TidyDoc tdoc, TidyBuffer* errbuf );
extern (C) int tidyRunDiagnostics( TidyDoc tdoc );

/**
 * Convert Tidy strings to their const array equivalents.
 */
pure nothrow inout(char)[] fromTidyString(R)(inout(R*)tidyString)
	if (is(R==ubyte) || is(R==char) || is(R==byte))
{
	return fromStringz(cast(inout(char*))tidyString);
}

public:

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
	shiftjis = "shiftjis",
	UNCHANGED = "UNCHANGED"
}

enum TidyNewline
{
	LF = "LF", CRLF = "CRLF", CR = "CR", UNCHANGED = "UNCHANGED"
}

enum TidyDoctype
{
	html5 = "html5",
	omit = "omit",
	automatic = "auto",
	strict = "strict",
	transitional = "transitional",
	user = "user",
	UNCHANGED = "UNCHANGED"
}

enum TidyDuplicateAttrs
{
	keepFirst = "keep-first",
	keepLast = "keep-last",
	UNCHANGED = "UNCHANGED"
}

enum TidyAutoBool
{
	yes = "yes",
	no = "no",
	automatic = "auto",
	UNCHANGED = "UNCHANGED"
}

enum TidyBool
{
	yes = "yes",
	no = "no",
	UNCHANGED = "UNCHANGED"
}
struct Tidier
{
	this(string input)
	{
		m_input = input;
	}

	int indentSpaces = 2;
	int wrapLen = 68;
	int tabSize = 8;
	TidyCharEncoding charEncoding = TidyCharEncoding.utf8;
	TidyCharEncoding inCharEncoding = TidyCharEncoding.utf8;
	TidyCharEncoding outCharEncoding = TidyCharEncoding.utf8;

	version(leftToDefault)
	{
	}
	else
	{

	}

	version(Windows)
	{
		TidyNewline newline = TidyNewline.CRLF;
	}
	else
	{
		TidyNewline newline = TidyNewline.LF;
	}

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
	bool showWarnings = true;
	bool quiet = false;
	TidyAutoBool indentContent = TidyAutoBool.no;
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
	bool numEntities = true;
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
	bool mark = true;
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

private:
	string m_input;
}

R tidy(R)(R input)
	if (isSomeString!R)
{
	return R();
}

void tidyDiagnostic()
{
	import std.stdio;
	writefln("%s", TidyDoctype.automatic);
	writefln("%s", TidyDuplicateAttrs.keepFirst);
	version(none)
	{
		import std.array;
		import std.format;
		import std.stdio;
		import std.regex;
		import std.uni;
		import std.utf;

		foreach (e; [EnumMembers!TidyOptionId])
		{
			string eString = format("%s", e);
			auto m = eString.matchFirst(ctRegex!`^Tidy`);
			string truncatedString = format("%s", m.post);

			string result;

			auto n = truncatedString.matchFirst(ctRegex!`^CSS`);

			if (!n.empty)
			{
				result = `css` ~ n.post;
			}
			else {
				if (truncatedString!=truncatedString.toUpper)
				{
					auto graphemes = truncatedString.byGrapheme.array;
					
					assert(!graphemes.empty);
					
					auto firstLetter = graphemes[0..1].byCodePoint.array.toUTF8.toLower;
					graphemes.popFront;
					auto restOfString = graphemes.byCodePoint.array.toUTF8;
					
					result = firstLetter ~ restOfString;
				}
				else
				{
					result = truncatedString.toLower;
				}
			}
			writefln("bool %s = true;", result);
		}
	}
}

int tidyTest()
{
	import std.stdio;

	string input = "<title>Foo</title><p>Foo!";

	TidyBuffer output;
	TidyBuffer errbuf;

	int rc = -1;

	TidyDoc tdoc = tidyCreate();                     // Initialize "document"
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
		rc = tidyParseString( tdoc, input.toStringz );           // Parse the input
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
			writef( "\nDiagnostics:\n\n%s", fromTidyString(errbuf.bp) );
		}
		writef( "\nAnd here is the result:\n\n%s", fromTidyString(output.bp) );
	}
	else
	{
		writefln( "A severe error (%d) occurred.", rc );
	}

	return rc;
}




R cleanHtml(R)(R input)
	if (isSomeString!R)
{
	string html = input;
	
	auto tidyDoc = tidyCreate();
	TidyBuffer tidyOutputBuffer;

	scope(exit)
	{
		// Free the memory.
		tidyBufFree(&tidyOutputBuffer);
		tidyRelease(tidyDoc);
	}

	// Configure Tidy
	// The flags tell Tidy to disable showing warnings
	auto configSuccess = // tidyOptSetBool(tidyDoc, TidyOptionId.TidyXmlOut, Bool.yes)
		tidyOptSetBool(tidyDoc, TidyOptionId.TidyQuiet, Bool.yes) &&
			tidyOptSetValue(tidyDoc, TidyOptionId.TidyIndentContent, "auto") &&
			tidyOptSetBool(tidyDoc, TidyOptionId.TidyNumEntities, Bool.yes) &&
			tidyOptSetBool(tidyDoc, TidyOptionId.TidyShowWarnings, Bool.no) &&
			tidyOptSetValue(tidyDoc, TidyOptionId.TidyCharEncoding, "utf8") &&
			tidyOptSetInt(tidyDoc, TidyOptionId.TidyWrapLen, 0);
	
	int tidyResponseCode = -1;
	

	// Parse input
	if (configSuccess)
	{
		tidyResponseCode = tidyParseString(tidyDoc, html.toStringz);
	}

	// Process HTML
	if (tidyResponseCode >= 0)
	{
		tidyResponseCode = tidyCleanAndRepair(tidyDoc);

		// Output the HTML to our buffer
		if (tidyResponseCode >= 0)
		{
			tidyResponseCode = tidySaveBuffer(tidyDoc, &tidyOutputBuffer);
		}
	}
	else //tidyResponseCode < 0 means there are errors from Tidy.
	{
		// throw ("Tidy encountered an error while parsing an HTML response. Tidy response code: " + tidyResponseCode);
	}

	// Grab the result from the buffer and then free Tidy's memory
	string result = (cast(char*)tidyOutputBuffer.bp).to!string;

	return result;
}