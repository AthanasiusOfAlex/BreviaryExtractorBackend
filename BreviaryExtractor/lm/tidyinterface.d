module lm.tidyinterface;

pragma(lib, "tidys");

import std.conv;
import std.string;
import std.traits;

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
extern (C) Bool tidyOptResetAllToDefault( TidyDoc tdoc );
