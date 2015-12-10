module lm.userfolders;

import std.path;

string getHomeFolder()
{
	version(Posix)
	{
		return expandTilde("~");
	}
	else version(Windows)
	{
		import std.process;
		
		try
		{
			return environment["userprofile"];
		}
		catch
		{
			throw new Exception("Returning the home folder is not yet implemented in Windows " ~
				"versions eariler than Windows XP.");
		}
	}
	else
	{
		throw new Exception("Returning the home folder is not yet implemented in this system.");
	}
}

string getDocumentsFolder()
{
	try
	{
		return buildPath(getHomeFolder, "Documents");
	}
	catch
	{
		throw new Exception("Returning the document folder is not yet implemented in this system.");
	}
}

string getLocalSettingsFolder()
{
	try
	{
		version(OSX)
		{
			return buildPath(getHomeFolder, "Library", "Application Support");
		}
		else version(Posix)
		{
			return buildPath(getHomeFolder, ".config");
		}
		else version(Windows)
		{
			import std.process;
			try
			{
				return environment["localappdata"];
			}
			catch
			{
				string exceptionMessage = "Returning the local settings folder requires at least Windows XP or later.";
				try
				{
					import std.file;
					
					string attemptVistaPath = buildPath(getHomeFolder, "AppData", "Local");
					if (exists(attemptVistaPath))
					{
						return attemptVistaPath;
					}
					else
					{
						string attemptXpPath = buildPath(getHomeFolder, "Local Settings");
						if(exists(attemptXpPath))
						{
							return attemptXpPath;
						}
						else
						{
							throw new Exception(exceptionMessage);
						}
					}
				}
				catch
				{
					throw new Exception(exceptionMessage);
				}
			}
		}
	}
	catch
	{
		throw new Exception("Returning the local settings folder is not yet implemented in this system.");
	}
}


string getCurrentWorkingFolder()
{
	return std.file.getcwd;
}

version(OSX)
{
	private extern (C) int _NSGetExecutablePath(char* buf, uint* bufsize);
}

/**
 * Returns the full-path file name of the executable that is running.
 * (or of the current process, if there is more than one). All links are
 * resolved, if necessary.
 */
string getCurrentProcessExecutable()
{
	string result;
	
	import std.path;
	
	version(OSX)
	{
		// The following code will get the size of the path.
		uint size;
		_NSGetExecutablePath(null, &size);
		
		// The following code will create a buffer and load it.
		auto buffer = new char[size];
		_NSGetExecutablePath(buffer.ptr, &size);
		
		result = buffer.idup;
	}
	else version (FreeBSD)
	{
		result = std.file.readLink("/proc/curproc/file");
	}
	else version (linux)
	{
		result = std.file.readLink("/proc/self/exe");
	}
	else version (Windows)
	{
		import core.sys.windows.windows;
		import std.windows.charset;
		
		immutable string failMessage = "For some reason, the path of the program " ~
			"could not be read.";
		
		// GetModuleFileNameA for ANSI.
		// GetModuleFileNameW for unicode (utf16).
		
		version(all)	// The version for Windows >= Windows 2000. Returns unicode.
		{
			import std.utf;
			
			wchar[MAX_PATH + 1] buffer; // MAX_PATH+1, because there could be a null char
			
			auto success = GetModuleFileNameW(null, buffer.ptr, MAX_PATH);
			
			if(success==0) // When success==0, it means GetModuleFileNameW has failed.
			{
				throw new Exception(failMessage);
			}
			
			result = buffer.toUTF8;
		}
		else version(none)	// Works with earlier versions of Windows, but not Unicode.
		{
			char[MAX_PATH + 1] buffer; // MAX_PATH+1, because there could be a null char
			
			import std.windows.charset;
			
			auto success = GetModuleFileNameA(null, buffer.ptr, MAX_PATH);
			
			if(success==0) // When success==0, it means GetModuleFileNameW has failed.
			{
				throw new Exception(failMessage);
			}
			
			// Copy the buffer to an immutable char[] (i.e., string), then
			// return a pointer, and finally convert from ANSI to UTF8.
			// (The function fromMBSz, which converts to UTF8, takes arguments
			// immutable (char)*, int.)
			result = buffer.idup.ptr.fromMBSz;
		}
	}
	else
	{
		throw new Exception ("Returning the current executable is not supported on this system.");
	}
	
	return result;
}