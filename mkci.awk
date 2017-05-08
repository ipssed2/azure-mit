# awk95 -f mkci.awk ci.txt
# mrr 2017-05-04
# input:            "name": "ci_custFirstName",
# output:  "ci_custFirstName": "[steps('customerInfo').ci_custFirstName]",
# 

BEGIN {
	FS = "\""
}
{
	name = $4
	line = "     \"" name" \": \"[steps('customerInfo')." name "]\","
	print line
}