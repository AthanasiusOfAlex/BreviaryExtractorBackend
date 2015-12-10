module preparehtml;

import arsd.dom;
import lm.domhelper;
import lm.tidyinterface;

import config;

/**
 * Prepares an HTML file, especially the header
 * as it ought to be done for this project.
 */
string prepareHtml(string input)
{
	auto document = new Document(input.cleanHtml);

	// Make sure it is unicode.
	document.makeItUnicode;

	// Set the author
	document.setAuthor(`Breviary`);
	
	// Make it link the CSS file.
	document.addLink(cssFile);

	return document.toString.cleanHtml;
}

string cleanHtml(string input)
{
	return lm.tidyinterface.cleanHtml(input);
}