#!/bin/bash
#set -x
filelist="filelog"
testUrl="https://localhost:8443"
searchStr="GOOGLE_URL"

git clone $1 && baseFolder=$(basename $1 .git)
echo $baseFolder && cd $baseFolder
git diff $2 $3 --name-only | grep -v "excl" > $filelist
echo "Comparing $2 $3"; echo "The list of files with differences are,"
while IFS= read -r line; do
echo -e "$line"
done < "$filelist"

while IFS= read -r line; do
    if grep -q $searchStr $line; then
    echo -e "$searchStr is found in : $line"
        if $(curl -v $testUrl --connect-timeout 5 2>&1 | grep -q "Connected to"); then
        echo "Successfully connected to $testUrl"
        else
        echo "Connectivity to $testUrl is not established"
        fi
    sed -i "s/${searchStr}/https:\/\/google.com/g" $line && echo "Sucessfully replaced $searchStr in $line"
jq -n '{"status": "success","url" : "https://google.com:443"}' > payload.json
curl -v -X POST -H "Content-Type: application/json" -d @file2.json http://localhost:8443 
    fi


done < "$filelist"
