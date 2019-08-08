# genXMLs
script to generate COSbench XML files for s3 benchmarking

Creates these XML files
FILENAME | Description
-------- | -----------
fill.xml | cluster fill workload (creates buckets and objects)
empty.xml | cluster empty (removes objects and buckets)
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
runtime | workstage duration in seconds
objSIZES | object sizes
numCONT | number of containers/buckets     
numOBJ  | number of objects (per bucket)
