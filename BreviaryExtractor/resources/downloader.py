#!/usr/bin/python

import sys
import re
import mechanize

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
    br = mechanize.Browser()

    br.open(optionsURI)
    br.select_form(nr=0)
  
    br.form["anno"] = year
    br.form["giorno"] = day
    br.form["mese"] = [month]
    br.form["lang"] = [language]
    br.submit()
  
    mypage = br.open(hours[hour])

    if fileName=="-":
      fo = sys.stdout
    else:
      fo = open(fileName, "w")
  
    try:
      fo.write(mypage.read())
    finally:
      fo.close

  except Exception as ex:
    print >> sys.stderr, "EXC: ", ex
    sys.exit(5)

else:
  print >> sys.stderr, "Usage: ", sys.argv[0], " output-file year month day language hour\n\nUse - for output-file if writing to standard output."