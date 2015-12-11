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

# for arg in sys.argv:
#   print arg
                    
if len(sys.argv) == 7:
  fileName = sys.argv[1]
  year     = sys.argv[2]
  month    = sys.argv[3]
  day      = sys.argv[4]
  language = sys.argv[5]
  hour     = sys.argv[6]

  try:
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

      if fileName=="-":
        outputFile = sys.stdout
      else:
        outputFile = open(fileName, "w")
  
      # Write its contents to the output file.  
      try:
        # To avoid problems with stdout, convert first to byte array,
        # then write to file.
        outputBytes = bytes(str(browser.parsed), 'utf-8')
        outputFile.buffer.write(outputBytes)

      finally:
        outputFile.close

  except Exception as ex:
    print ("EXC: ", ex, sys.stderr)
    sys.exit(5)

else:
  print("Usage: ", sys.argv[0], " output-file year month day language hour\n\nUse - for output-file if writing to standard output.", file=sys.stderr)