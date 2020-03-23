# CHOP UP LARGE SOUND FILE USING 2-TIERED TEXTGRID
# ================================================
# This script chops up a larger file into smaller files based on a textgrid with two tiers.
#   - It creates a unique filename for each sound by combining the text from an optional prefix
#     with text from tiers 1 and 2.
#   - If a file with the same name already exists, a copy will be saved in the backup directory
#     and the previous file overwritten.
#   - A report is saved to the "output" folder
#
# One of a set of scripts to help automate some of my PhD research.
# for Praat 6.0.36
#
# Antoin Eoin Rodgers
# rodgeran@tcd.ie
# Phonetics and speech Laboratory, Trinity College Dublin
# October 28, 2017

### TIER ANNOTATION INSTRUCTIONS
###    1. The .TextGrid file must have the same name as the .wav file and be saved in the same directory
###    2. The .TextGrid file must have 2 interval tiers only:
###          - TIER 1: should contain a general reference (e.g. speaker code or phrase code)
###          - TIER 2: should contain a rep number for the general reference
### UI FORM
###    1. PREFIX
###          - Prefix all output files (e.g. speaker code, gender, location)
###          - Leave blank for no prefix
###    2. PASS BAND FREQUENCY
###          - The lower limit for the pass band filtering
###          - This should be AT LEAST 10 Hz below the lowest F0 in the files.

##################
### User Input ###
##################
### Input Form
form Input Parameters
    natural pass_band_frequency 45
    sentence output_file_prefix
endform
### Get file to process
soundFile$ = chooseReadFile$: "Open a sound file"

#Read in target wave file
Read from file: soundFile$
soundID = selected()
fs = Get sampling frequency

######################################
### READ TEXTGRID FILE (IF EXISTS) ###
######################################
textGridFile$ = left$ (soundFile$, rindex (soundFile$, "."))+ "TextGrid"
### check textgrid exists
textGrid_okay = fileReadable (textGridFile$)
if textGrid_okay = 0
    exitScript: "NO TEXTGRID FOR SELECTED .WAV FILE." + newline$
endif

### read in textgrid
Read from file: textGridFile$
gridID = selected()

###run validity checks for input textgrid
numTiers = Get number of tiers
if numTiers != 2
    exitScript: "TEXTGRID FOR SELECTED .WAV FILE SHOULD ONLY HAVE 2 TIERS." + newline$
endif
isInterval1 = Is interval tier: 1
isInterval2 = Is interval tier: 2
if isInterval1 + isInterval2 != 2
    exitScript: "EACH TEXTGRID TIER MUST BE AN INTERVAL TIER." + newline$
endif
totalIntervals1 = Get number of intervals: 1
totalIntervals2 = Get number of intervals: 2
if totalIntervals1 > totalIntervals2
    exitScript: "TIER 1 SHOULD HAVE AT LEAST AS MANY TIERS A TIER 2." + newline$
endif
notBlank1 = Count intervals where: 1, "is not equal to", ""
notBlank2 = Count intervals where: 2, "is not equal to", ""
if notBlank1 * notBlank2 = 0
    exitScript: "AT LEAST ONE TIER IS BLANK." + newline$
endif

#############################
### SET UP OUTPUT FOLDERS ###
#############################
outputDir$ = chooseDirectory$: "Choose a directory for save file"
outputText$ =  "Saving Files to directory: " +outputDir$
@SetUpFolders: outputDir$

### start report
text$ = "========================"
writeInfoLine: text$
writeFileLine: reportFilePath$, text$
text$ = "Chop Up Large Sound File" + newline$ + "========================"
  ... + newline$ + date$ ( ) + newline$
@reportUpdate: reportFilePath$, text$

### input directory
rightmostSlash = rindex (soundFile$, "/")
inputDir$ = left$(soundFile$, rightmostSlash)
inputFile$ = right$(soundFile$, length(soundFile$) - rightmostSlash)

@ChopLines: inputDir$, 50, "Input directory:  """, """"
inputDirText$ = newText$
@ChopLines: outputDir$, 50, "Output directory: """, """"
outputDirText$ = newText$

text$ = "Input .wav file:  """ + inputFile$ + """" + newline$
  ... + inputDirText$ + newline$
  ... + outputDirText$ + newline$ + newline$
  ... + "Stop band : 0 - " + string$(pass_band_frequency) + " Hz"  + newline$
@reportUpdate: reportFilePath$, text$

### CREATE NEW SOUND OBJECTS BASED ON TIER 1 INTERVAL AND ARRAY OF NON-BLANK INTERVAL NAMES
validIntervals2 = 0
### Create unique output file names: tier1 (code) + "_" + tier2 (rep)
for i from 1 to totalIntervals2
    i$ = Get label of interval: 2, i
    if i$<>""
        validIntervals2 = validIntervals2 + 1
        rep$ =  i$
        start_point = Get start point: 2, i
        end_point = Get end point: 2, i
        mid_point = (start_point + end_point) / 2
        code_num = Get interval at time: 1, mid_point
        code$ = Get label of interval: 1, code_num
        unique_name$[validIntervals2] = code$ + "_" + rep$
    endif
endfor

### extract reps from sound file
selectObject: gridID
plusObject: soundID
Extract non-empty intervals: 2, "no"
totalFiles = numberOfSelected ()
start_sound = selected(1)
end_sound = selected(-1)
selectObject: soundID
plusObject: gridID
Remove

### append file prefix if necessary
if output_file_prefix$ <> ""
    output_file_prefix$ = output_file_prefix$ + "_"
endif

### Remove low-frequency noise and save new sound file
text$ = "Output files:"
@reportUpdate: reportFilePath$, text$
for i from start_sound to end_sound
    backedUp$ = ""
    j = i - start_sound + 1
    selectObject: i
    Filter (stop Hann band): 0, pass_band_frequency, 10
    iTemp = selected()
    fileNameCur$ = outputDir$ + "/" + output_file_prefix$ + unique_name$[j] + ".wav"
    curFileExists = fileReadable (fileNameCur$)
    backupNum = 0
    while curFileExists
        backupNum += 1
        curBackUp$ = backupPath$ + output_file_prefix$
               ... + unique_name$[j] + "_bk" + string$(backupNum) + ".wav"
        curFileExists = fileReadable (curBackUp$)
        if curFileExists = 0
            backedUp$ = " (backup: " + output_file_prefix$ + unique_name$[j]
                  ... + "_bk" + string$(backupNum) + ".wav)"
            Read from file: fileNameCur$
            Save as WAV file: curBackUp$
            Remove
        endif
    endwhile
    selectObject: iTemp
    Save as WAV file: fileNameCur$
    text$ = "   " + output_file_prefix$ + unique_name$[j] + ".wav" + backedUp$
    @reportUpdate: reportFilePath$, text$
    selectObject: i
    plusObject: iTemp
    Remove
endfor

text$ = newline$ + "================"
  ... + newline$ + "PROCESS COMPLETE"
  ... + newline$ + "================"
@reportUpdate: reportFilePath$, text$

##################
### procedures ###
##################
### report update
procedure reportUpdate: .reportFile$, .lineText$
    appendInfoLine: .lineText$
    appendFileLine: .reportFile$, .lineText$
endproc

### create text for directory info
procedure ChopLines: .originalText$, .lineLength, .newText$, .endtext$
    .spaces$ = ""
    for .i to length(.newText$)
        .spaces$ = .spaces$ + " "
    endfor
    .dir_len = length(.originalText$)
    .full_chunks = floor(.dir_len/.lineLength)
    .remainder = .dir_len - .full_chunks * .lineLength
    for .i to .full_chunks
        .newText$ = .newText$ + mid$(.originalText$, 1 + .lineLength * (.i - 1), .lineLength)
                ... + newline$ + .spaces$
    endfor
    .newText$ = .newText$ + right$(.originalText$, .remainder) + .endtext$
    newText$ = .newText$
endproc

### Set up folders
procedure SetUpFolders: .directory$
    output_dir$ = "output"
    backup_dir$ = "backup"
    reportName$ = "create_sound_files_report_"
        ... + right$(replace$(replace$(date$()," ","", 0),":","",0),15)
        ... + " .txt"
    reportPath$ = .directory$ + "/" + output_dir$
    backupPath$ = .directory$ + "/" + backup_dir$
    createDirectory: reportPath$
    createDirectory: backupPath$
    reportPath$ = reportPath$ + "/"
    backupPath$ = backupPath$ + "/"
    reportFilePath$ = reportPath$ + reportName$
endproc