module breviarydownloader;

import std.datetime;
import std.path;
import std.stdio;

import arsd.dom;
import lm.datehelper;
import lm.regexhelper;
import lm.userfolders;

import helperfunctions;
import config;

/*
 * 1. Selecting the number of days, start date, etc. (Through arguments)
 * 2. Make a progress indicator.
 * 3. Join days together
 * 4. Add logical divisions.
 * 5. Add links to other sections (psalmody).
 * 6. Tweak the formatting
 */

class BreviaryDownloader {
	this(Date startDate)
	{
		runConstructor(1, Language.en, buildPath(getHomeFolder, "Dropbox", "daily_ibreviary"), true, startDate);
	}

	this(int numberOfDays=7,
		Language defaultLanguage=Language.en,
		string outputFolder = buildPath(getHomeFolder, "Dropbox", "daily_ibreviary"),
		bool joinHoursOnTheSameDay=true,
		Date startDate = cast(Date)Clock.currTime)
	{
		runConstructor(numberOfDays, defaultLanguage, outputFolder, joinHoursOnTheSameDay, startDate);
	}


	private void runConstructor(int numberOfDays,
		Language defaultLanguage,
	    string outputFolder,
	    bool joinHoursOnTheSameDay,
		Date startDate)
	{
		import std.datetime;

		m_language = defaultLanguage;

		m_outputFolder = outputFolder;
		m_joinHoursOnTheSameDay = joinHoursOnTheSameDay;

		m_date = startDate;

		try
		{
			// Copy CSS file to output folder.
			void copyCssFileToOutputFolder(string cssFile)
			{
				import std.file;
				import std.path;

				string newCssFile = buildPath(m_outputFolder, cssFile);

				if(!exists(m_outputFolder))
				{
					mkdirRecurse(m_outputFolder);
				}

				copy(cssFile, newCssFile);
			}
			copyCssFileToOutputFolder(cssFile);

			// Set up the progress indicator.
			import progressindicator;
			auto progressIndicator = new ProgressIndicator!ProgressStdout(numberOfDays*getAllMembers!Hora.length, 80);

			foreach(dayOffset; 0..numberOfDays)
			{
				m_date = startDate + dur!"days"(dayOffset);

				m_cumulativeHtmlText = "";


				// Download day's files.
				foreach(hora; getAllMembers!Hora)
				{
					this.m_hora = hora;
					downloadHoraAndSave();
					progressIndicator.uptick;
				}
			}
			status = 0;
		}
		catch(Exception exc)
		{
			status = 1;
			message = exc.msg;
		}
	}

	int status;
	string message;

private:
	string m_outputFolder;
	bool m_joinHoursOnTheSameDay;
	File m_outputFile;
	Hora m_hora;
	Date m_date;
	string m_currentHtmlText;
	string m_cumulativeHtmlText;

	Language m_language;

	void downloadHoraAndSave()
	{
		// Download file, extract, and polish.
		m_currentHtmlText = downloadHora().extractDiv("inner").postProcess(m_date, m_hora);
		
		// Save file.
		saveHora();
	}

	void saveHora()
	{
		import std.conv;
		import std.file;
		import std.path;

		import lm.userfolders;

		if (!exists(m_outputFolder))
		{
			mkdirRecurse(m_outputFolder);
		}

		if (m_joinHoursOnTheSameDay)
		{
			import std.conv;
			import std.string;
			import arsd.dom;
			import lm.tidyinterface;

			// Extract the body of the current hour and add it to the cumulative HTML.
			auto currentHtmlDocument = new Document(m_currentHtmlText);

			// Add a "cap" if this the first hour.
			if (m_hora==getAllMembers!Hora[0])
			{
				m_cumulativeHtmlText ~= format(`<div class="opening">` ~
				                               `<h1 id="top" class="title">Breviary</h1>` ~
				                               `<p class="date">` ~ m_date.toLongDate ~ `</p>` ~
				                               `<p class="gotohours"><a href="#%s">Office of Readings</a></p>` ~
				                               `<p class="gotohours"><a href="#%s">Morning Prayer</a></p>` ~
				                               `<p class="gotohours"><a href="#%s">Daytime Prayers</a></p>` ~
				                               `<p class="gotohours"><a href="#%s">Evening Prayer</a></p>` ~
				                               `<p class="gotohours"><a href="#%s">Night Prayer</a></p></div>`,
				                               Hora.office, Hora.lauds, Hora.daytime,
				                               Hora.vespers, Hora.complines);
			}

			m_cumulativeHtmlText ~= format(`<div class="hour">`);

			m_cumulativeHtmlText ~= format(`%s<p class="gotohours">` ~
			                               `<a href="#%s">%s</a></p></div>`,			                               
			                               currentHtmlDocument.getFirstElementByTagName("body").innerHTML,
			                               m_hora.to!string,
			                               `Return to beginning of hour`);

			if (m_hora==(getAllMembers!Hora[$-1]))
			{
				auto document = new Document(m_cumulativeHtmlText.cleanHtml);

				document.makeItUnicode;
				document.getFirstElementByTagName(`title`).appendText(`Breviary ` ~ m_date.toLongDate);
				document.setAuthor(`Breviary`);
				document.addLink(cssFile);

				m_outputFile = File(buildPath(m_outputFolder, `Breviary ` ~
			    	                          m_date.toLongDate ~ 
			            	                  `_` ~ m_language.to!string ~ `.html`), `w`);
				m_outputFile.write(document.toString.cleanHtml);
			}
		}
		else
		{
			m_outputFile = File(buildPath(m_outputFolder,
			                            m_date.toSimpleString ~ 
			                            `_` ~ nextEnum(m_hora).to!string ~
			                            `_` ~ m_hora.to!string ~ `.html`), `w`);
			m_outputFile.write(m_currentHtmlText);
		}
		

		m_outputFile.close;
	}

	// DEPRECATED
	string downloadHora()
	{
		import std.conv;
		import std.datetime;
		import std.file;
		import std.path;
		import std.process;
		import lm.tidyinterface;
		
		auto downloader = buildPath(getcwd(), `downloader.py`);
		if (!exists(downloader))
		{
			throw new Exception(`The downloader, 'downloader.py', does not exist. Please reinstall.`);
		}
		
		// Download the hour.
		auto downloadProcess = execute(
			[`/opt/local/bin/python2.7`,
			downloader,
			`-`, m_date.year.to!string,
			m_date.month.to!uint.to!string,
			m_date.day.to!string,
			m_language.to!string,
			m_hora.to!string]);

		if (downloadProcess.status == 5)
		{
			throw new Exception(`Unable to access the Internet.`);
		}
		else if (downloadProcess.status != 0)
		{
			throw new Exception(`Downloader returned status ` ~
			                    downloadProcess.status.to!string ~
			                    ` and could not be run.\n` ~
			                    `Output: "` ~ downloadProcess.output ~ `"`);
		}

		return downloadProcess.output.cleanHtml;
	}
};

private string extractDiv(string input, string division)
{
	import arsd.dom;
	import lm.tidyinterface;
	
	auto document = new Document(input);

	auto divs = document.root.getElementsByClassName(division);


	if (divs.length==0)
	{
		return "";
	}
	else
	{
		return divs[0].innerHTML.cleanHtml;
	}
}

private string postProcess(string input, Date date, Hora hora)
{
	import std.conv;
	import std.range;

	import arsd.dom;
	
	import helperfunctions;
	import config;
	import lm.regexhelper;
	import lm.tidyinterface;
	
	string preprocessedInput;

	// Put nonbreaking space before * and †.
	preprocessedInput = input.simpleReplaceAll!`\s*(<span class="rubrica">([\*†]|&#8224;)</span>)`(`&nbsp;$1`);

	/***
		<p>******</p>
		<p><a href="HTTP://www.ibreviary.com/new/donazione.html">DONATE</a></p>
		<p>to support the continued development of the iBreviary</p>
		<p><a href="http://www.ibreviary.org/en/newsletter.html">SUBSCRIBE</a> iBreviary newsletter<a name="psalmMP"></a></p>
	***/

	// Save any links embedded in a fundraising part.
	preprocessedInput
		= preprocessedInput.simpleReplaceAll
			!`<p>\s*\*+\s*</p>.*?SUBSCRIBE.*?(<a[^>]*(name|id)\s*=\s*"[^"]*"[^>]*>.*?</a>)*?</p>`
			(`$1`);

	// Remove any other fundraising part.
	preprocessedInput
		= preprocessedInput.simpleReplaceAll!`<p>\*+</p>.*?<p>.*?SUBSCRIBE.*?</p>`(``);

	// Final cleanup of "fundraising" sections.
	preprocessedInput = preprocessedInput.simpleReplaceAll!`<p><a href="#menu">- Menu -</a></p>`(``);

	// Remove <br><br> and change to </p><p>.
	preprocessedInput = preprocessedInput.changeDoubleBrToP;

	// Tweak the "go to" statements, so that they don't get picked up by Calibre's headings detector.
	{
		// The following will replace, e.g.
		//       <a href="#hymn_office">Go to the Hymn</a>
		// with
		//       Go to the <a href="#hymn_office">Hymn</a>
		// Or
		//       <a href="#hymn_office">Go to Psalm 24</a>
		// with
		//       Go to <a href="#hymn_office">Psalm 24</a>
		preprocessedInput = preprocessedInput
			.simpleReplaceAll!`(<a[^<>]*>)([gG]o\s*to\s*)(the\s*)?(Psalm)?([^<>]*</a>)`(`$2$3$1$4$5`);
	}

	// Prepare document for tweaking:
	auto document = new Document(preprocessedInput.cleanHtml);

	// Downgrade the headings by one (h1->h2, h2->h3, etc.)
	document.offsetAllHeadings;

	// Some assumptions that should be safe.
	assert(!document.getElementsByTagName(`head`).empty); // We may safely assume there is a "head".
	assert(!document.getElementsByTagName(`title`).empty); // We may safely assume there is a "title".
	assert(!document.getElementsByTagName(`h2`).empty);
	assert(!document.root.getElementsByClassName(`sezione`).empty);

	// Make the "hour" the ID for the first heading:
	{
		auto heading = document.getFirstElementByTagName(`h2`);
		heading.setAttribute(`id`, hora.to!string);
	}

	// Add generic class "normal" to all block elements without it.
	document.addGenericClassToBlockElements;

	// Add author
	document.setAuthor(`Breviary`);

	// Set the title, using the text of "sezione."
	auto sezione = document.root.getElementsByClassName(`sezione`)[0];
	string titleText = sezione.innerHTML;
	document.setTitle(titleText ~ ` ` ~ date.toLongDate);

	// Replace "Breviary" with title.
	auto headingTwo = document.getFirstElementByTagName(`h2`);
	headingTwo.removeAllChildren;
	headingTwo.appendText(titleText);

	// Delete "sezione"
	assert(!(sezione.parentNode is null));
	assert(!(sezione.parentNode.parentNode is null));

	auto sezioneParagraph = sezione.parentNode;
	auto sezioneContainer = sezione.parentNode.parentNode;

	sezioneContainer.removeChild(sezioneParagraph);
	
	// Add a date.
	auto dateNode = document.createElement("p");
	dateNode.setAttribute("class", "date");
	dateNode.appendText(date.toLongDate);
	headingTwo.parentNode.insertAfter(headingTwo, dateNode);

	// Get rid of the fundraising info
	auto fundraisingNodes = document.root.getElementsByClassName("fundraising");

	foreach(node; fundraisingNodes)
	{
		assert(!(node.parentNode is null));
		node.parentNode.removeChild(node);
	}

	// Make the HREF references unique.
	document.convertNameToId;
	document.fixHrefs(hora);

	return document.toString.cleanHtml;
}

/**
 * Offsets the headings by 'offset'. For example, an 
 * offset of 1 turns h1 into h2, h2 into h3, and so on. 
 * HTML allows h1 to h6, so any offsets exceeding what is
 * allowed will simply be reduced to the greatest
 * allowable. It gives the new headings the class of
 * "normal".
 */
private void offsetAllHeadings(ref Document document, long offset=1)
{
	immutable long totalNumberOfHeadings = 6;

	if (offset==0)
	{
		return;	// Nothing to do if the offset is 0!
	}
	else if (offset < 1-totalNumberOfHeadings)
	{
		offset =  1 - totalNumberOfHeadings;
	}
	else if (offset > totalNumberOfHeadings-1)
	{
		offset = totalNumberOfHeadings - 1;
	}

	// Determine the lower and upper limits.
	import std.algorithm;
	long lowerLimit = min(max(1, 1 - offset), totalNumberOfHeadings);
	long upperLimit = max(min(totalNumberOfHeadings, totalNumberOfHeadings - offset), 1);

	foreach_reverse(i; lowerLimit..upperLimit+1)
	{
		import std.string;
		string headingTagName = format("h%s", i);
		string offsetTagName = format("h%s", i+offset);

		auto headings = document.getElementsByTagName(headingTagName);
		foreach(heading; headings)
		{
			auto newHeading = document.createElement(offsetTagName);
			newHeading.setAttribute("class", "normal");
			newHeading.appendHtml = heading.innerHTML;
			heading.parentNode.replaceChild(heading, newHeading);
		}
	}
}

private string toLongDate(Date date)
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

private void makeItUnicode(ref Document document)
{
	auto charset = document.createElement("meta");
	auto head = document.getFirstElementByTagName("head");

	assert(!(head is null));

	charset.setAttribute("charset", "utf-8");
	head.prependChild(charset);
}

private void setAuthor(ref Document document, string author)
{
	auto headNode = document.getFirstElementByTagName("head");
	auto newNode = document.createElement("meta");
	newNode.setAttribute("name", "author");
	newNode.setAttribute("content", author);
	headNode.prependChild(newNode);
}

private void addLink(ref Document document, string file, string rel="stylesheet", string type="text/css")
{
	//   <link href="filename.css" rel="stylesheet" type="text/css"/>

	auto headNode = document.getFirstElementByTagName("head");
	auto newNode = document.createElement("link");
	newNode.setAttribute("href", file);
	newNode.setAttribute("rel", "stylesheet");
	newNode.setAttribute("type", "text/css");
	headNode.prependChild(newNode);
}

private void setTitle(ref Document document, string title)
{
	auto titleNode = document.getFirstElementByTagName("title");
	titleNode.appendText(title);
}

/**
 * Removes the 'name' attribute in 'a' tags and
 * turns it into an 'id', if there is none.
 */
private void convertNameToId(ref Document document)
{
	auto aTags = document.getElementsByTagName("a");
	foreach(a; aTags)
	{
		if (a.hasAttribute("name"))
		{
			string saveName = a.getAttribute("name");
			if (!a.hasAttribute("id")) // if it already has an ID, leave it alone.
			{
				if (document.idIsFree(saveName))	// Only add an ID if it will be unique.
				{
					a.setAttribute("id", saveName);
				}
			}

			// Remove any "name" attributes in any event.
			while(a.hasAttribute("name"))
			{
				a.removeAttribute("name");
			}
		}
	}
}

/**
 * Check to see if this ID is free (i.e., not already used).
 */
private bool idIsFree(ref Document document, string id)
{
	if (document.getElementById(id) is null)
	{
		return true;
	}
	else
	{
		return false;
	}
}

private void fixHrefs(ref Document document, Hora hour)
{
	auto aTags = document.getElementsByTagName("a");

	foreach(Element a; aTags)
	{
		if (a.hasAttribute("href"))
		{
			string saveHref = a.getAttribute("href");
			string id = saveHref.removePound;
			while (a.hasAttribute("href"))
			{
				a.removeAttribute("href");
			}

			// Now search for the corresponding ID.
			auto nodeReferredTo = document.getElementById(id);

			// Now, change it to something unique in both reference and ID (if applicable).
			import std.conv;
			string newHref = saveHref ~ "_" ~ hour.to!string;
			string newID = newHref.removePound;

			a.setAttribute("href", newHref);

			if (!(nodeReferredTo is null) && document.idIsFree(newID))
			{
				while(nodeReferredTo.hasAttribute("id"))
				{
					nodeReferredTo.removeAttribute("id");
				}
				nodeReferredTo.setAttribute("id", newID);
			}
		}
	}
}

private string removePound(string input)
{
	return matchFirst(input, ctRegex!"^#+").post;
}

private string changeDoubleBrToP(string input)
{
	import lm.tidyinterface;

	return replaceAll(input, ctRegex!(r"\s*<br\s*/?>\s*<br\s*/?>\s*", "s"), "</p><p>").cleanHtml;
}

private void addGenericClassToBlockElements(ref Document document)
{
	// Just walk through the tree and find classless block elements, and fix.
	foreach(Element node; document.root.tree)
	{
		if (node.tagName.isMatchOf!"p|div|h[0-9]|br" && !node.hasAttribute("class"))
		{
			node.setAttribute("class", "normal");
		}
	}
}

private void testfun(string input)
{
	import std.string;

	foreach(string line; input.splitLines)
	{
		if(line.isMatchOf!"Office of Readings")
		{
			stderr.writeln();
			stderr.writeln(line);
			break;
		}
	}
}

private void findAndMarkFundraisingSections(string className="fundraising")
{

}