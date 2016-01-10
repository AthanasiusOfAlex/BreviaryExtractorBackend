#!/usr/bin/env python

import sys
import re
from robobrowser import RoboBrowser

import warnings    # to work around a bug in RoboBrowser

baseURI = "http://www.ibreviary.com/m2/"
rootURI = baseURI + "breviario.php"
optionsURI = baseURI + "opzioni.php"
hourURI = rootURI + "?s="

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
		browser.open(optionsURI)

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
		raise Exception("Instruction must have six arguments (`download`, year, month, day, language, hour). " + str(len(arguments)) + " were given.")

	return tuple(arguments[1:6])

def sanitizeOutput(input):
	regex = re.compile( '\s+')
	return 'HTML:' + regex.sub(' ', input) + '\n'

try:
	for line in sys.stdin:
		arguments = line.split()

		if arguments[0]=="download":
			year, month, day, language, hour = parseInstruction(arguments)

			output = downloadHour(year, month, day, language, hour)
			output = sanitizeOutput(output)

			sys.stdout.buffer.write(bytes(output, 'utf-8'))
			sys.stdout.flush()

		elif arguments[0]=="quit":
			sys.stdout.write("DONE\n")
			break

		else:
			raise Exception("Unknown input: " + line.strip() + '\n')

except Exception as ex:
	sys.stdout.write("EXC: " + str(ex) + '\n')
	sys.stdout.flush()

sys.stdout.flush()