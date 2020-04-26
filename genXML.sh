#!/bin/bash
# genXML.sh - creates the COSbench workload files
#   fillWorkload.xml, emptyWorkload.xml, ioWorkload.xml
##################################################

# START YOUR EDITS HERE---------------------------------------
# Use this to label your workload files
testname="test2_"        # prepended to each XML workload name
#+++++++++++++
# VARIABLES to configure workload file generation
# Used in ALL workloads
akey="166XCLIN89VKM832RBUG"
skey="c0ztXqzWnW3pfcwdOs8mVSH7GbMXEatuUeQQUldr"
# some S3 providers (Ceph RGW, Minio) require path_style_access=true
pathstyle="true"
# this is messy for sed to work must escape backslashes
endpt="http:\/\/192.168.0.210:9000"
runtime="60"           # duration (in seconds) of each workstage
objSIZES="c(64)KB"
numCONT=5
numOBJ=50
numOBJoffset=$(( (numOBJ + 1) ))  # offset to avoid overlapping buckets
numOBJmax=$(( (numOBJ * 2) ))     # multiply by two for WRITEs & DELETEs
#numOBJmax=$numOBJ # for HYBRID steady-state Object Count

# Specify number of workers by workload
fillWORKERS=4
seqWORKERS=4
randomWORKERS=4
mixedWORKERS=4

# TYPICALLY you will not need to edit below HERE-------------------

# Calculating Container Start and End for Random/Sequential Write Workload
numWRCONTSTART=$(( (numCONT+1) ))
numWRCONTEND=$(( (numCONT+10) ))

# We need a unique bucket name on AWS
# generate random 20 char string (lowercase only)
# used as "cprefix" value in workloads
cprefix=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 20 | head -n 1)

# the credentials, endpoint and path style
theAUTH="accesskey=${akey};secretkey=${skey};endpoint=${endpt};path_style_access=${pathstyle}"

# MIXED workload requires lots of definition
# Ratios for operation types - MUST add up to 100%
rdRatio=60
wrRatio=16
delRatio=14
listRatio=10
totalRatio=$(( (rdRatio + wrRatio + delRatio + listRatio) ))
if [ $totalRatio -ne 100 ]; then
    echo "Operation ratios (rdRatio, wrRatio, ...) must equal 100%"; exit
fi
# Conf portions for the Read and List operation statements
# NOTE: COSbench will FAIL if job attempts to READ a non-existing Object
rdCONF="containers=u(1,${numCONT});objects=u(1,${numOBJ})"
listCONF="${rdCONF}"
# Object ranges for the Write and Delete operation statements
# TO ENSURE that we are legitimately writing new objects, we are
#      using a higher objcnt for these than read/list operations
wrCONF="containers=u(1,${numCONT});objects=u(${numOBJoffset},${numOBJmax})"
delCONF="${wrCONF}"

#########################################################
# Workload files - Templates and XMLs
FILLtemplate="XMLtemplates/TMPL_fill.xml"
FILLxml="${testname}fill.xml"
EMPTYtemplate="XMLtemplates/TMPL_empty.xml"
EMPTYxml="${testname}empty.xml"
# Next up - SEQUENTIAL workload file
SEQtemplate="XMLtemplates/TMPL_seqops.xml"
SEQxml="${testname}seqops.xml"
# Next up - RANDOM workload file
RANDOMtemplate="XMLtemplates/TMPL_randomops.xml"
RANDOMxml="${testname}randomops.xml"
# Next up - MIXED workload file
MIXEDtemplate="XMLtemplates/TMPL_mixedops.xml"
MIXEDxml="${testname}mixed.xml"
# the arrays for template and workload filenames
declare -a THEtemplates_arr=(
           "${FILLtemplate}"
           "${EMPTYtemplate}"
           "${SEQtemplate}"
           "${RANDOMtemplate}"
           "${MIXEDtemplate}"
           )
declare -a THExmls_arr=(
           "${FILLxml}"
           "${EMPTYxml}"
           "${SEQxml}"
           "${RANDOMxml}"
           "${MIXEDxml}"
           )
#
# TEMPLATE keywords and VARS
# for each workload: pre-existing keywords in the template file
#                    are used to populate xml files
declare -a THEkeys_arr=(
           "THEauth"
           "FILLworkers"
           "SEQworkers"
           "RANDOMworkers"
           "MIXEDworkers"
           "THEsizes"
           "THEnumCont"
           "THEnumObj"
           "THEmaxNumObj"
           "THEcprefix"
           "THEruntime"
           "MIXEDrdRatio"
           "MIXEDwrRatio"
           "MIXEDdelRatio"
           "MIXEDlistRatio"
           "MIXEDrdConf"
           "MIXEDlistConf"
           "MIXEDwrConf"
           "MIXEDdelConf"
	   "NUMwrcontstart"
	   "NUMwrcontend"
           )
declare -a THEvalues_arr=(
           "${theAUTH}"          # auth credential
           "${fillWORKERS}"      # number of workers for FILL/EMPTY
           "${seqWORKERS}"       # number of workers seqops
           "${randomWORKERS}"    # number of workers randomops
           "${mixedWORKERS}"     # number of workers mixedops
           "${objSIZES}"         # Object sizes
           "${numCONT}"          # number of Containers
           "${numOBJ}"           # number of Objects
           "${numOBJmax}"        # max number of Objects (empty and mixed)
           "${cprefix}"          # unique 20 char string to please aws s3
           "${runtime}"          # duration of each workstage
           "${rdRatio}"          # Read ratio
           "${wrRatio}"          # Write ratio
           "${delRatio}"         # Delete ratio
           "${listRatio}"        # List ratio
           "${rdCONF}"           # config for Read operations
           "${listCONF}"         # config for List operations
           "${wrCONF}"           # config for Write ops
           "${delCONF}"          # config for Delete ops
	   "${numWRCONTSTART}"   # Start Value of Write Container
	   "${numWRCONTEND}"     # End Value of Write Container
           )
#
# END VARIABLES
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

echo "Creating COSbench XML workload files"
let i=0
for thisTemplate in "${THEtemplates_arr[@]}"; do
    thisXML="${THExmls_arr[i]}"
# backup the XML file if it exists
    if [ -f "${thisXML}" ]; then
        mv "${thisXML}" "${thisXML}_bak"
        echo "> ${thisXML} exists - moved to ${thisXML}_bak"
    fi
# copy the Template and make edits
    cp "${thisTemplate}" "${thisXML}"
# replace keywords with values
    let j=0
    for origValue in "${THEkeys_arr[@]}"; do
        newValue="${THEvalues_arr[j]}"
        sed -i "s/${origValue}/${newValue}/g" $thisXML
        j=$(( $j + 1 ))
    done
    echo "> created COSbench workload file: ${thisXML}"
    i=$(( $i + 1 ))
done
