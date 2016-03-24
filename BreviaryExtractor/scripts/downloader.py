#!/usr/bin/env python

import sys
import re
from requests import Session
from robobrowser import RoboBrowser

import warnings    # to work around a bug in RoboBrowser

baseURI = "http://www.ibreviary.com/m2/"
rootURI = baseURI + "breviario.php"
optionsURI = baseURI + "opzioni.php"
hourURI = rootURI + "?s="

proxy = None      # We will use this later, if necessary.

hours =  { 'options'  : optionsURI,
			'base'     : rootURI,
			'lauds'    : hourURI + "lodi",
			'morning'  : hourURI + "lodi",
			'office'   : hourURI + "ufficio_delle_letture",
			'midday'   : hourURI + "ora_media",
			'daytime'  : hourURI + "ora_media",
			'vespers'  : hourURI + "vespri",
			'evening'  : hourURI + "vespri",
			'complines': hourURI + "compieta" }

def downloadHour(year, month, day, language, hour):
	with warnings.catch_warnings():
		warnings.simplefilter("ignore")
		browser = RoboBrowser(history=True)

		# Set the iBreviary options
		if proxy==None:
			browser.open(optionsURI)
		else:
			browser.open(optionsURI, proxies={'http': proxy})
		
		optionsForm = browser.get_form(action='/m2/opzioni.php')

		optionsForm["anno"] = year
		optionsForm["giorno"] = day
		optionsForm["mese"] = month
		optionsForm["lang"] = language
		browser.submit_form(optionsForm)

		# Now download the desired hour.
		browser.open(hours[hour])
		  
		# Return the output as a string, making sure it is terminated by a newline.
		return str(browser.parsed)

def parseInstruction(arguments):
	assert arguments[0]=="download", "Instruction must begin with `download`."

	if len(arguments)!=6:
		raise Exception("Download instruction must have exactly six arguments (`download`, year, month, day, language, hour). " + str(len(arguments)) + " were given.")

	return tuple(arguments[1:6])

def getProxy(arguments):   # For now, we will be taking at most one proxy server, an HTTP server.
	assert arguments[0]=="proxy", "Instruction must begin with `proxy`."

	if len(arguments)!=2:
		raise Exception("Proxy instruction must have exactly two arguments (`proxy` and the address of the proxy server).")

	proxyString = arguments[1]

	# The proxy can be set to "None", in which case the proxy string be None (null).
	if proxyString=="None":
		return (None, "PROXY OK")

	# Now, make sure it is a valid proxy address. If not, change nothing and give error message.
	regex = re.compile('https?://([^@:]+:)?([^@:]+@)?[\d\w\.-]+(:\d+)?/?')
	match = re.match(regex, proxyString)

	if match==None:
		return (proxy, "PROXY ERROR")   # NB: 'proxy' is the global variable. Returning it means it won't be changed.

	# Add final slash (/) if it is missing.
	if proxyString[-1:] != '/':
		proxyString += '/'

	return (proxyString, "PROXY OK")

def sanitizeOutput(input):
	regex = re.compile('\s+')
	return 'HTML:' + regex.sub(' ', input) + '\n'

try:
	for line in sys.stdin:
		arguments = line.split()

		if len(arguments)==0:
			continue

		if arguments[0]=="download":
			year, month, day, language, hour = parseInstruction(arguments)
		
			output = downloadHour(year, month, day, language, hour)
			output = sanitizeOutput(output)
		
			sys.stdout.buffer.write(bytes(output, 'utf-8'))
			sys.stdout.flush()
		
		elif arguments[0]=="proxy":
			proxy, status = getProxy(arguments)
			sys.stdout.write("PROXY: " + status + "\n")
			sys.stdout.flush()
					
		elif arguments[0]=="quit":
			sys.stdout.write("DONE\n")
			break
		
		else:
			raise Exception("Unknown input: " + line.strip() + '\n')

except Exception as ex:
	excType, excObj, excTraceback = sys.exc_info()
	sys.stdout.write("EXC: '" + str(ex) + "' at line " + str(excTraceback.tb_lineno) + '\n')
	sys.stdout.flush()

sys.stdout.flush()