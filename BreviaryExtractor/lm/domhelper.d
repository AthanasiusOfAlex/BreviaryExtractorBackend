/**
 * This module contains functions to
 * simplify the use of the dom
 * module. You still have to import
 * the arsd.dom module.
 */

module lm.domhelper;

import std.algorithm;

import arsd.dom;

/**
 * Check to see if this ID is free (i.e., not already used).
 */
bool idIsFree(ref Document document, string id)
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

void makeItUnicode(ref Document document)
{
	auto metaNode = document.createElement("meta");
	auto headNode = document.makeSureThereIsAHead;

	metaNode.setAttribute("http-equiv", "content-type");
	metaNode.setAttribute("content", "text/html; charset=utf-8");
	headNode.prependChild(metaNode);
}

/**
 * Checks to make sure the document
 * has a "head." Create one if
 * necessary.
 */
Element makeSureThereIsAHead(Document document)
{
	auto headNode = document.getFirstElementByTagName("head");
	if (headNode is null) // If there was no head, create one.
	{
		headNode = document.createElement("head");
		document.root.prependChild(headNode); // "head" should be first child of "html"
	}

	return headNode;
}

void setAuthor(ref Document document, string author)
{
	auto headNode = document.makeSureThereIsAHead;
	auto metaNode = document.createElement("meta");
	metaNode.setAttribute("name", "author");
	metaNode.setAttribute("content", author);
	headNode.prependChild(metaNode);
}

/**
 * Adds a link to a file (by default
 * a css style sheet).
 */
void addLink(ref Document document, string file, string rel="stylesheet", string type="text/css")
{
	//   <link href="filename.css" rel="stylesheet" type="text/css"/>
	
	auto headNode = document.makeSureThereIsAHead;

	auto linkNode = document.createElement("link");
	linkNode.setAttribute("href", file);
	linkNode.setAttribute("rel", rel);
	linkNode.setAttribute("type", type);
	headNode.prependChild(linkNode);
}

/**
 * Removes the 'name' attribute in 'a' tags and
 * turns it into an 'id', if there is none.
 */
void convertNameToId(ref Document document)
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
 * Extracts the body to yield only the interior part of an html file.
 */
string extractBody(string input)
{
	auto document = new Document(input);
	return document.extractBody;
}

/**
 * Extracts the body to yield only the interior part of an html file.
 */
string extractBody(ref Document document)
{
	auto bodyNode = document.bodyNode;

	return bodyNode.toString;
}

/**
 * Remove all examples of a given attribute.
 */
string removeAttributeEverywhere(string input, string attribute)
{
	auto document = new Document(input);
	document.removeAttributeEverywhere(attribute);
	return document.toString;
}

/**
 * Remove all examples of a given attribute.
 */
void removeAttributeEverywhere(ref Document document, string attribute)
{
	// We are only interested in the attributes found in the body.
	foreach(Element node; document.getFirstElementByTagName(`body`).tree.filter!(a => a.hasAttribute(attribute)))
	{
		node.removeAttribute(attribute);
	}
}

/**
 * Returns the body of an HTML document
 * or the root element if there is no body.
 */
Element bodyNode(ref Document document)
{
	Element result;

	result = document.getFirstElementByTagName("body");

	if (result is null)
	{
		result = document.root;
	}

	return result;
}