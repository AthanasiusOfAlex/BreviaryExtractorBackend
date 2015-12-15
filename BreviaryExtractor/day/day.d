module day;

import std.algorithm;
import std.datetime;
import std.signals;
import std.string;
import std.traits;

import arsd.dom;
import lm.datehelper;
import lm.domhelper;
import lm.tidydocument:cleanHtml;

import config;
import hour;
import preparehtml;
import progressindicator;
import config;

/**
 * This class will put together hours to
 * make an entire day.
 */
class Day
{
	this(T)(Date date, Language language, ref ProgressIndicator!T progressIndicator)
	{
		this.date = date;
		this.language = language;
		mID = format("top_%s", date.toString);
		mTitle = "Breviary";
		mBookTitle = format("%s %s %s", mTitle, options.language, date);

		connect(&progressIndicator.uptick);

		// It is important to construct the file names first, since
		// I will be using them to prepare the resource files.
		mMainFileName = format("%s_%s_%s.html", mTitle, options.language, date);
		mTocFileName  = format("toc_%s_%s.ncx", options.language, date);
		mOpfFileName  = format("%s_%s_%s.opf", mTitle, options.language, date);

		loadAndPrepareResourceFiles;

		mDocument = joinHours;
		addCap();
		addReturnToTop();
		addPageBreaks();
	}

	// The text of a full day of prayers.
	@property string text()
	{
		return mDocument.toString.cleanHtml;
	}

	// Public access to the TOC and OPF files.
	@property string tocFile() { return mTocFile; }
	@property string opfFile() { return mOpfFile; }

	@property string mainFileName() { return mMainFileName; }
	@property string tocFileName()  { return mTocFileName;  }
	@property string opfFileName()  { return mOpfFileName;  }

	@property string bookTitle() { return mBookTitle; }

	mixin Signal!(long);

private:
	Date date;
	Language language;
	string mID;
	string mTitle;
	string mBookTitle;

	// We will need these in order to convert to MOBI.
	string mTocFile;
	string mOpfFile;

	immutable string mMainFileName;
	immutable string mTocFileName;
	immutable string mOpfFileName;

	Document mDocument;
	Hour[] hours;

	/**
	 * Loads the TOC and OPF files, which need
	 * to be updated as we go along.
	 */
	void loadAndPrepareResourceFiles()
	{
		import std.file;
		import lm.regexhelper;

		// Load the files.
		try
		{
			mOpfFile = readText(opfTemplate);
			mTocFile = readText(tocTemplate);
		}
		catch
		{
			throw new Exception("It appears that the OPF or TOC template is corrupt. Please fix or reinstall.");
		}

		// Now, prepare them, feeding in the file names and titles.
		mTocFile = mTocFile.simpleReplaceAll!`%file%`(mMainFileName);
		mOpfFile = mOpfFile.simpleReplaceAll!`%mainFileName%`(mMainFileName);
		mOpfFile = mOpfFile.simpleReplaceAll!`%tocFileName%`(mTocFileName);
		mOpfFile = mOpfFile.simpleReplaceAll!`%bookTitle%`(mBookTitle);
	}

	// This will update the TOC file based on the current hour.
	void updateTOCFile(Hour hour)
	{
		import std.conv;
		import lm.regexhelper;

		mTocFile = mTocFile.simpleReplaceAll("%" ~ hour.hora.to!string ~ "%", hour.hourID);
	}

	/**
	 * Makes a single unified DOM document
	 * with all the hours together.
	 */
	Document joinHours()
	{
		string text;
		
		foreach(hora; EnumMembers!Hora)
		{
			auto hour = new Hour(date, hora, language);
			hours ~= hour;
			text ~= hour.textInDiv;
			updateTOCFile(hour);
			uptickProgressIndicator;
		}
		
		text = text.prepareHtml;

		return new Document(text);
	}

	void uptickProgressIndicator()
	{
		emit(1);
	}

	/**
	 * Add the navigation links at top of day.
	 */
	void addCap()
	{
		Element bodyNode = mDocument.bodyNode;

		// First add a 'div' key at the top with class "opening".
		auto divOpening = mDocument.createElement("div");
		divOpening.setAttribute("class", "opening");
		bodyNode.prependChild(divOpening);

		// Now, add a title.
		auto h1 = mDocument.createElement("h1");
		h1.setAttribute("id", mID);
		h1.setAttribute("class", "title");
		divOpening.appendChild(h1);

		h1.appendText(mTitle);

		// Add a date
		auto dateNode = mDocument.createElement("p");
		dateNode.setAttribute("class", "date");
		divOpening.appendChild(dateNode);

		dateNode.appendText(date.toLongDate);

		// Open a div for the links.
		auto divGotohours =  mDocument.createElement("div");
		divGotohours.setAttribute("class", "gotohours");
		divOpening.appendChild(divGotohours);

		// Now add the links
		foreach(hour; hours)
		{
			auto par = mDocument.createElement("p");
			par.setAttribute("class", "gotohours");
			divGotohours.appendChild(par);

			auto link = mDocument.createElement("a");
			link.setAttribute("href", format("#%s", hour.hourID));
			par.appendChild(link);

			link.appendText((hour.hora).horaFullTitle(language));
		}
	}

	/**
	 * Add navigation link at bottom of each hour.
	 */
	void addReturnToTop()
	{
		foreach(hour; hours)
		{
			auto h2 = mDocument.getElementById(hour.hourID);
			if (h2 !is null)
			{

				auto div = h2.getParent;
				if (div !is null)
				{
					div.appendHtml(format(`<p class="gotohours"><a href="#%s">%s</a></p>`, hour.hourID, "Return to top of hour."));
					div.appendHtml(format(`<p class="gotohours"><a href="#%s">%s</a></p>`, mID, "Return to today’s table of contents."));
				}
			}
		}
	}

	/**
	 * Add page breaks to each section
	 */
	void addPageBreaks()
	{
		foreach(bodyElement; mDocument.root.getElementsByTagName("body"))
		{
			foreach (div; bodyElement.childNodes.filter!(a => a.tagName=="div"))
			{
				div.appendHtml(`<div class="pagebreak"></div>`);
			}
		}
	}

}