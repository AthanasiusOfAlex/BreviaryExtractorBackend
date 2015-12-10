module ibreviarydomhelper;

import arsd.dom;

import helperfunctions;
import lm.regexhelper;

/**
 * Implements an input range that gives
 * access to a desired sequence of nodes,
 * beginning with a "titleNode" that
 * defines the starting point, and ending
 * with the node that matches the criteria
 * of the "endgameRegex".
 */
struct ElementRangeTitleToEndgame
{
    this(Element titleNode, string endgameRegex)
    {
        m_endgameRegex = endgameRegex;
        m_frontNode = m_getInitialFrontNode(titleNode);
    }
    
    // Implementation of input range.
    @property empty() { return m_isEndgame(); }
    @property Element front() { return m_frontNode; }
    void popFront() { m_frontNode = m_getNextNode(); }
    
protected:
    string m_endgameRegex;
    Element m_frontNode;
    
    Element m_getInitialFrontNode(Element titleNode)
    {
        if (titleNode is null)
        {
            return null;
        }

        return titleNode.nextSibling;
        // return searchForwardByTag(titleNode, "#text", r"[^\s]+");   // Find the first available nonempty text node.
    }
    
    Element m_getNextNode()
    {
        if (m_frontNode is null)
        {
            return null;
        }
        else
        {
            return m_frontNode.nextSibling;
        }
    }
    
    
    bool m_isEndgame()
    {
        if (m_frontNode is null)
        {
            return true;
        }
        
        string text = extractTextFromSpan(m_frontNode);
        
        if (!matchFirst(text, m_endgameRegex).empty)
        {
            return true;
        }
        
        return false;
    }
}



/**
 * Gets the value from a node without fear of crashing. 
 */
string extractValue(Element node)
{
	if (node is null)
	{
		return "";
	}
	
    return node.nodeValue;
}

/**
 * Returns the text surrounded by <span></span>
 * or a similar tag.
 */
string extractTextFromSpan(Element node)
{
	return extractValue(getTextNodeFromSpan(node));
}

Element getTextNodeFromSpan(Element node)
{
	if (node is null)
	{
		return null;
	}
	
	auto childNode = node.firstChild;
	
	if (childNode is null)
	{
		return null;
	}
	
	if (childNode.tagName!="#text")
	{
		return null;
	}
	
	return childNode;
}

/**
 * Finds the first child node of a kind like a [span]
 * that contains the given text. We can optionally limit
 * our search to a particular class.
 */
Element findFirstWithText(Element baseNode, string tagName, string text, string className = "")
{
	if (baseNode is null)
	{
		return null;
	}
	
	Element[] childNodes;
	if (className=="")
	{
		childNodes = baseNode.getElementsByTagName(tagName);
	}
	else
	{
		childNodes = baseNode.getElementsByClassName(className);
	}
	
	foreach (node; childNodes)
	{
		if(node.tagName==tagName)
		{
			foreach(textNode; node.getElementsByTagName("#text"))
			{
				if(textNode.nodeValue==text)
				{
					return node;
				}
			}
		}
	}
	
	return null;
}

Element findFirstWithClass(Element parent,string className, string tagName = "")
{
	Element[] childNodes;
	
	childNodes = parent.getElementsByClassName(className);
	
	foreach (node; childNodes)
	{
		if (tagName=="" || node.tagName==tagName)
		{
			return node;
		}
	}
	
	return null;
}

/**
 * Finds the first available node of tag 'tagName'.
 * Optionally provide a regex that must match the
 * node value.
 */
Element searchForwardByTag(Element start, string tagName, string re = "")
{
    Element node = start.nextSibling; 
    while(!(node is null))
    {
        if (node.tagName==tagName && (re=="" || !matchFirst(node.nodeValue, regex(re,"s")).empty))
        {
            return node;
        }
        node = node.nextSibling;
    }    
    
    return null;
}



/**
 * Searches forward among the siblings of 'start' in order
 * to find child notes with 'text'.
 * The search may be narrowed with an optional class name.
 */
Element searchForwardWithText(Element start, string tagName, string text, string className = "")
{
	Element node = start.nextSibling; 
	while(!(node is null))
	{
		if(!matchFirst(node.className, className).empty) // if 'className' is a subset of nextNode.classname
		{
			foreach(textChildNode; node.getElementsByTagName("#text"))
			{
				if(node.tagName==tagName && !matchFirst(textChildNode.nodeValue, text).empty)
				{
					return node;
				}
			}
		}
		node = node.nextSibling;
	}
	
	
	return null;
}

Element getTextNodeAfterSpan(Element spanNode)
{
	if (spanNode is null)
	{
		return null;
	}
	else
	{
		return spanNode.nextSibling;
	}
}

/**
 * Returns the text after a [span][/span].
 * For example, from
 * "[span]Ant.[/span] Come sing joyfylly to the Lord."
 * extract " Come sing joyfylly to the Lord."
 */
string extractTextAfterSpan(Element spanNode)
{
	return extractValue(getTextNodeAfterSpan(spanNode));
}

/**
 * Returns antiphons preceded by "Or:" that are immediately
 * an antiphon preceded by "Ant." The 'start' element
 * should be the 'span' that surrounds "Ant."
 */
string[] findAllSecondAntiphons(Element start, string secondTitle = "Or:", string terminatingCondition = r"\*|Ant\.")
{
	import std.string;
	
	string[] result;
	char[] testingText;
	
	auto currentNode = searchForwardWithText(start, "span", secondTitle);
	while (!(currentNode is null) && matchFirst(testingText, terminatingCondition).empty)
	{
		string antiphon = extractTextAfterSpan(currentNode).dup;
		testingText = extractTextFromSpan(currentNode).dup;
		
		if (antiphon!="")
		{
			result ~= antiphon.strip;
		}
		currentNode = searchForwardWithText(currentNode, "span", secondTitle ~ "|" ~ terminatingCondition);
	}
	
	return result;
}

/**
 * A convenience function.
 */
Element getAntiphonSpan(Element baseParagraph, string title = "Ant.")
{
	return findFirstWithText(baseParagraph, "span", title);
}

/**
 * A convenience function.
 */
string getFirstAntiphon(Element antiphonSpan)
{
	import std.string;
	return extractTextAfterSpan(antiphonSpan).strip;
}

Element findFirstNodeWithText(Element baseNode, string input)
{
    if (baseNode is null)
    {
        return null;
    }

    foreach (node; baseNode.tree)
    {
        if (node.nodeValue.isMatchOf(input))
        {
            return node;
        }
    }

    return null;
}

Element findFirstSpanWithText(Element baseNode, string input, string tagName="span")
{
    if (baseNode is null)
    {
        return null;
    }
    
    foreach (Element node; baseNode.tree)
    {
        if (node.nodeValue.isMatchOf(input))
        {
            auto parent = node.parentNode;
            if (!(parent is null))
            {
                if (parent.tagName==tagName)
                {
                    return parent;
                }
            }
        }
    }
    
    return null;
}