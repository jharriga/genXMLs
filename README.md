# genXMLs
genXML.sh script to generate COSbench XML files for s3 benchmarking. Also includes 'cbparser.py', a script which parses COSbench workload results archive directory and produces text results file. USAGE: ./cbparser.py -d archive/w25-empty-s3/

**NOTE: genXML.sh generates a random string as container prefix name to avoid AWS S3 name collisions**

Creates these XML files

FILENAME | Description
-------- | -----------
fill.xml | cluster fill workload (creates buckets and objects) **must be run as first workload**
empty.xml | cluster empty (removes objects and buckets) **must be run as last workload**
seqops.xml | performs sequential reads then writes
randomops.xml | performs random reads then writes
mixedops.xml | performs mixture of read, list, write, deletes

Edit genXMLs.sh and set access key, secret key and endpoint

VARIABLE | Description
-------- | -----------
akey | s3 access key
skey | s3 secret key
endpt | s3 endpoint

Further define workload conditions by defining these

VARIABLE | Description
-------- | -----------
testname | name prepended to all XML files
runtime | workstage duration in seconds **- not used in fill or empty workloads**
objSIZES | object sizes
numCONT | number of containers/buckets     
numOBJ  | number of objects (per bucket)
