#!/bin/bash

data=$1

if [[ -z "$data" ]]; then # All tests
	prove t/
elif [[ ${data} == "html" ]]; then # HTML result file
	prove -m -Q --state=last --formatter=TAP::Formatter::HTML t/ > html/test_data.html
else # Run specific file
	prove t/"$data"*
fi

exit 0
