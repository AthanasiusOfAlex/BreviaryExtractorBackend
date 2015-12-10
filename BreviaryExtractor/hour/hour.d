module hour;

import std.algorithm;
import std.conv;
import std.datetime;
import std.range;
import std.regex;
import std.string;
import std.traits;

import arsd.dom;
import lm.datehelper;
import lm.domhelper;
import lm.regexhelper;

import config;
import downloadhour;
import preparehtml;
import config;

/**
 * This class will take the raw input
 * and produce well-formed hour.
 * 
 * The constructor may either be raw text
 * or a date, hour, and language.
 */
class Hour
{
	/**
	 * The default constructor takes the last
	 * date, time, and language used to
	 * downloads the appropriate hour.
	 * By default, the first download will be
	 * tomorrow’s office of readings. (If
	 * you want start with something different,
	 * use the manual date, hora, and
	 * language constructor for the first run.)
	 */
	this()
	{
		mHora = currHora;
		mDate = currDate;
		getText;
		processText;
	}
	this(Date date, Hora hora, Language language)
	{
		this.mHora = hora;
		this.mDate = date;
		getText(date, hora, language);
		processText;
	}

	this(string rawInput)
	{
		mHora = currHora;	// This is intentionally arbitrary.
		mDate = currDate;

		getText(rawInput);
		processText;
	}

	/**
	 * The title.
	 */
	@property string title()
	{
		return mDocument.title;
	}

	/**
	 * Set the title.
	 */
	@property void title(string title)
	{
		mDocument.title = title;

		Element h2 = mDocument.getFirstElementByTagName("h2");
		if (h2 is null)
		{
			h2 = mDocument.createElement("h2");

			Element root = mDocument.getFirstElementByTagName("body");
			if (root is null)
			{
				root = mDocument.root;
			}

			root.prependChild(h2);
		}
		else
		{
			h2.removeAllChildren;
		}

		Element titleTextNode = mDocument.createTextNode(title);
		h2.appendChild(titleTextNode);
	} 

	/**
	 * The text of the hour.
	 */
	@property string text()
	{
		return mDocument.toString.prepareHtml;
	}

	/**
	 * The text of the hour without headers.
	 */
	@property string textBodyOnly()
	{
		return mDocument.extractBody;
	}

	/**
	 * The text of the hour encapsulated in a 'div'.
	 */
	@property string textInDiv()
	{
		return format(`<div class="hour">%s</div>`, mDocument.extractBody);
	}

	/**
	 * The date of the hour.
	 */
	@property Date date()
	{
		return mDate;
	}

	/**
	 * The ID of the hour.
	 */
	@property string hourID()
	{
		return mHourId;
	}

	/**
	 * The type of hour (office, lauds,
	 * vespers, etc.)
	 */
	@property Hora    hora()     { return mHora;     }

	/**
	 * The DOM document object.
	 */
	@property Document document() { return mDocument; }

private:
	string mHourBody;
	Hora  mHora;
	Date   mDate;
	string mHourId;
	string workingText;

	Document mDocument;

	static Date currDate;
	static Hora currHora = Hora.complines;
	static Language currLanguage = Language.en;
	static Date today;
	static Date yesterday;

	void getText()
	{
		makeSaneCurrDate();
		getText(currDate, currHora, currLanguage);
	}

	void getText(Date date, Hora hora, Language language)
	{
		defaultInitialization;
		workingText = downloadHour(date, hora, language);
		setStaticPropertiesForNextDownload;
	}

	void getText(string rawInput)
	{
		workingText = rawInput;
	}

	void processText()
	{
		// First, make any changes that need to be made directly in
		// the text, and return the resulting DOM document.
		mDocument = preProcess();

		// The following manipulate the internal document object.
		offsetAllHeadings;
		makeFirstHeadingID;
		fixHtmlHeader;
		fixHtmlMainText;

		// Make any changes specific to the hour
		makeHourSpecificChanges;

		// Make any changes that need to made directly in the text,
		// and re-make the document:
		mDocument = postProcess();
	}

	/**
	 * Extracts the contents of the "inner"
	 * 'div' node, if it exists. Otherwise
	 * the contents of the 'body' node.
	 * (If it cannot find even that, it just
	 * returns the contents unchanged.)
	 */
	string extractInner(string input)
	{
		auto document = new Document(input);
		
		// This gives us all 'div's with class 'inner'.
		auto innerDivs = document.root.getElementsByClassName("inner").filter!(a => a.tagName=="div");

		string result;

		if (innerDivs.empty) // If the div is not found, just return the body contents.
		{	
			result = document.extractBody;
		}
		else
		{
			result = innerDivs.front.innerHTML;
		}

		return result;
	}

	/**
	 * Apply any corrections that require direct
	 * access to the text, but before manipulation
	 * of the DOM.
	 */
	Document preProcess()
	{
		// Extract the essential text and remove all the
		// fluff before and after it.
		workingText = extractInner(workingText.prepareHtml).prepareHtml;

		// Put nonbreaking space before * and †.
		workingText = workingText.simpleReplaceAll!`\s*(<span class="rubrica">([\*†]|&#8224;)</span>)`(`&nbsp;$1`);

		// Remove any embedded links in a "fundraising" section.
		workingText = workingText.simpleReplaceAll
			!`<p>\s*\*+\s*</p>.*?SUBSCRIBE.*?(<a[^>]*(name|id)\s*=\s*"[^"]*"[^>]*>.*?</a>)*?</p>`
				(`$1`);

		// Remove any other fundraising part.
		workingText = workingText.simpleReplaceAll!`<p>\*+</p>.*?<p>.*?SUBSCRIBE.*?</p>`(``);

		// Final cleanup of "fundraising" sections.
		workingText = workingText.simpleReplaceAll!`<p><a href="#menu">- Menu -</a></p>`(``);

		// Remove <br><br> and change to </p><p>.
		workingText = workingText.simpleReplaceAll!`\s*<br\s*/?>\s*<br\s*/?>\s*`(`</p><p>`);
		
		// Tweak the "go to" statements, so that they don't get picked up by Calibre's headings detector.
		// The following will replace, e.g.
		//       <a href="#hymn_office">Go to the Hymn</a>
		// with
		//       Go to the <a href="#hymn_office">Hymn</a>
		// Or
		//       <a href="#hymn_office">Go to Psalm 24</a>
		// with
		//       Go to <a href="#hymn_office">Psalm 24</a>
		workingText = workingText
			.simpleReplaceAll!`(<a[^<>]*>)([gG]o\s*to\s*)(the\s*)?(Psalm)?([^<>]*</a>)`(`$2$3$1$4$5`);

		// Change plus sign with Maltese Cross
		workingText = workingText.simpleReplaceAll!`\+`(`&#10016;`);

		// Change 'R.' to responsum.
		workingText = workingText.simpleReplaceAll!`(<span\s+class\s*=\s*"rubrica"\s*>\s*)(R.)(\s*</span>)`(`$1&#8479;$3`);

		// Change 'V.' to versicle.
		workingText = workingText.simpleReplaceAll!`(<span\s+class\s*=\s*"rubrica"\s*>\s*)(V.)(\s*</span>)`(`$1&#8483;$3`);

		// Clean up html and return the document.
		workingText = workingText.prepareHtml;

		return new Document(workingText);
	}

	/**
	 * Offsets the headings by 'offset'. For example, an 
	 * offset of 1 turns h1 into h2, h2 into h3, and so on. 
	 * HTML allows h1 to h6, so any offsets exceeding what is
	 * allowed will simply be reduced to the greatest
	 * allowable.
	 */
	void offsetAllHeadings(long offset=1)
	{
		immutable long totalNumberOfHeadings = 6;

		// The following adjusts 'offset', in case it exceeds
		// the total number of headings.
		// It idea is that, setting the 'offset' high will
		// collapse all headings to h6, and setting it very
		// low will collapse all headings to h1.
		if (offset==0)
		{
			return; // Nothing to do if the offset is 0!
		}
		else if (offset < 1-totalNumberOfHeadings)
		{
			offset =  1 - totalNumberOfHeadings;
		}
		else if (offset > totalNumberOfHeadings-1)
		{
			offset = totalNumberOfHeadings - 1;
		}

		// Things that should hold true:
		assert(!mDocument.getElementsByTagName("html").empty, "Please input a well-formed HTML document.");
		assert(!mDocument.getElementsByTagName("body").empty, "Please input a well-formed HTML document.");

		// Determine the lower and upper limits.
		long lowerLimit = min(max(1, 1 - offset), totalNumberOfHeadings);
		long upperLimit = max(min(totalNumberOfHeadings, totalNumberOfHeadings - offset), 1);
		
		foreach_reverse(i; lowerLimit..upperLimit+1)
		{	
			string headingTagName = format("h%s", i);
			string newTagName = format("h%s", i+offset);
			
			auto headings = mDocument.getElementsByTagName(headingTagName);
			foreach(heading; headings)
			{
				auto newHeading = mDocument.createElement(newTagName);
				newHeading.appendHtml = heading.innerHTML;
				heading.parentNode.replaceChild(heading, newHeading);
			}
		}
	}

	/**
	 * Make the "hour" the ID for the first heading.
	 */
	void makeFirstHeadingID(string headingTag = `h2`)
	{
		auto heading = mDocument.getFirstElementByTagName(headingTag);

		// Give up if there are no appropriate headings.
		if (heading !is null)
		{
			mHourId = format("%s_%s", mHora.to!string, mDate.toString);	// Take advantage to save this.
			heading.setAttribute(`id`, mHourId);
		}
	}

	/**
	 * DEPRECATED
	 */
	void addGenericClassToBlockElements(string className = "normal")
	{
		// Just walk through the tree and find classless block elements, and fix.
		foreach(Element node; mDocument.root.tree.filter!(a => a.tagName.isMatchOf!`p|div|br` && !a.hasAttribute("class")))
		{
			node.setAttribute("class", className);
		}
	}

	void fixHtmlHeader()
	{
		version(none)
		{
			// Set the title, using the text of "sezione."
			auto sezioni = mDocument.root.getElementsByClassName(`sezione`);

			if (!sezioni.empty)	// Don't bother if there is no 'sezione'.
			{
				mDocument.title = format("%s %s", sezioni.front.innerText, mDate.toLongDate);
			}
		}
		version(all)
		{
			// Set the title.
			mDocument.title = horaFullTitle(mHora, currLanguage);
		}
	}

	void fixHtmlMainText()
	{
		// Replace "Breviary" with title.
		auto headingTwo = mDocument.getFirstElementByTagName(`h2`);

		if (headingTwo !is null)
		{
			headingTwo.removeAllChildren;
			headingTwo.appendText(mDocument.title);
		}

		// Delete "sezione"
		auto sezioni = mDocument.root.getElementsByClassName(`sezione`);

		if (!sezioni.empty)
		{
			auto sezioneParagraph = sezioni.front.parentNode;

			if (sezioneParagraph ! is null)
			{
				auto sezioneContainer = sezioneParagraph.parentNode;

				if (sezioneContainer !is null)
				{
					sezioneContainer.removeChild(sezioneParagraph);
				}
			}
		}

		// Remove the extra 'name' attributes.
		// (Tidy duplicates 'name' with an identical
		// 'id' attribute.)
		mDocument.removeAttributeEverywhere(`name`);

		// This will make the Hrefs and corresponding IDs
		// unique, even if we have to merge them.
		fixHrefs(mDocument, mHora);
	}

	void fixHrefs(ref Document document, Hora hour)
	{
		foreach(Element node; document.getElementsByTagName("a").filter!(a => a.hasAttribute(`href`)))
		{
			string saveHref = node.getAttribute("href");
			string id = removePound(saveHref);
			while (node.hasAttribute("href"))
			{
				node.removeAttribute("href");
			}
			
			// Now search for the corresponding ID.
			auto nodeReferredTo = document.getElementById(id);
			
			// Now, change it to something unique in both reference and ID (if applicable).
			string newHref = format("%s_%s_%s", saveHref, hour.to!string, mDate.toString);
			string newID = removePound(newHref);
			
			node.setAttribute("href", newHref);
			
			if (nodeReferredTo !is null && document.idIsFree(newID))
			{
				while(nodeReferredTo.hasAttribute("id"))
				{
					nodeReferredTo.removeAttribute("id");
				}
				nodeReferredTo.setAttribute("id", newID);
			}
		}
	}

	string removePound(string input)
	{
		return matchFirst(input, ctRegex!"^#+").post;
	}

	void makeHourSpecificChanges()
	{
		switch (mHora)
		{
			case Hora.office:
				workingText = mDocument.toString.prepareHtml;

				workingText = workingText.simpleReplaceAll!`(<p>\s*<span class="rubrica">\[In view of the omission.*?<span class="rubrica">\]</span>\s*</p>)`(`<div class="makeupreading">$1</div>`);
				mDocument = new Document(workingText.prepareHtml);
				break;
			case Hora.lauds:
				break;
			case Hora.daytime:
				break;
			case Hora.vespers:
				break;
			case Hora.complines:
				break;
			default:
				break;
		}
		
	}

	/**
	 * Transformations that must be used using regex
	 * replacements, but after the changes using the
	 * DOM model.
	 */
	Document postProcess()
	{
		workingText = mDocument.toString.prepareHtml;

		// Do stuff to the text.

		return new Document(workingText.prepareHtml);
	}

	void defaultInitialization()
	{
		if (today==Date(1,1,1))	// I only want to set this once. Date(1,1,1) is the default initialized value for Date's.
		{
			today = cast(Date)Clock.currTime;
		}
		yesterday = today - dur!"days"(1);
	}

	void makeSaneCurrDate()
	{
		if (currDate < earliestDate)
		{
			currDate = yesterday;
		}
	}

	void setStaticPropertiesForNextDownload()
	{
		if (currHora==EnumMembers!Hora[$-1])
		{
			currDate += dur!"days"(1);
		}
		currHora = nextEnum(currHora);
	}
}
