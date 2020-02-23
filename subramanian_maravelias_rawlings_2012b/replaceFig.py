import re
import sys

#this is the file to read in the regular expression
TexFileToRead = sys.argv[2]
f = open(TexFileToRead,'r')
#TextToWrite ="\\\\begingroup\\\\endlinechar=-1"  +f.read().replace('\\','\\\\')+"\\\\endgroup"
TextToWrite = f.read().replace('\\','\\\\')
TexFileName = TexFileToRead.split('.')[0]
FileExtension = TexFileToRead.split('.')[1]
f.close()
#this is the file that will be replaced
TexFileToReplace = sys.argv[1]
#string to substitute 


if FileExtension == 'tex':
 # StrToSub = "\\\\resizebox.*\\\\input{"+TexFileName+"}}"
 StrToSub = "\\\\input{"+TexFileName+"}"
#endif
if FileExtension == 'bbl':
 StrToSub = '\\\\bibliographystyle{abbrvnat}\n{\\\\scriptsize\n\\\\IfFileExists{paper.bib}{\\\\bibliography{paper}}{\\\\bibliography{abbreviations,articles,proceedings,books,unpub}}\n}\n'

f = open(TexFileToReplace,'r')
MainText = f.read()
f.close()

if FileExtension == 'tex':
 StrtoAddSub = "\\\\includegraphics{"+TexFileName+"}"
 SubtoAdd = "\\\\includegraphics{"+TexFileName+".pdf}"
 TextToWrite = re.sub(StrtoAddSub,SubtoAdd,TextToWrite,0,0)
#end

#MainText = re.sub(StrtoAddSub,MainText1,SubtoAdd,0,0)
NewText = re.sub(StrToSub,TextToWrite,MainText,0,0)

f = open(TexFileToReplace,'w')
f.write(NewText)
f.close()
