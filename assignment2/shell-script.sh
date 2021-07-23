#!/bin/bash
#set -x
filelist="filelog"
testUrl="https://google.com:443"
localUrl="http://localhost:8443"
searchStr="GOOGLE_URL"
counter=0

### Look for jq in the system and install it if not present
if ! [ -x "$(command -v jq)" >/dev/null 2>&1 ]; then
    echo "jq is not installed. Installing it now."
    yum install jq >/dev/null
fi

#Cloning the git repository
git clone --depth 2 --branch $3 $1 && baseFolder=$(basename $1 .git) 2>&1
if [ $? ]; then
    echo -e "Successfully cloned $1\n" && cd $baseFolder
else
    echo -e "error cloning the repo. Exiting"
    exit 1
fi

#Comparing the differences between 2 tags and display the file names
echo -e "Comparing repository for tags $2 $3 \nThe list of files with differences are,"
git diff $2 $3 --name-only

#Listing files excluding files start with "excl"
echo -e "\nListing differences excluding files starting with \"excl\""
git diff $2 $3 --name-only | grep -v "^excl" | tee -a $filelist
echo -e ""

#Checking for search string in the flie list
while IFS= read -r line; do
    if grep -q $searchStr $line; then
        echo -e "$searchStr is found in : $line"
        let counter=counter+1
        #Testing connectivity to test URL - https://google.com:443
        if $(curl -v $testUrl --connect-timeout 5 2>&1 | grep -q "Connected to"); then
            echo -e "Successfully connected to $testUrl"
        else
            echo -e "Connectivity to $testUrl is not established"
        fi
        #Replacing the search string GOOGLE_URL
        sed -i "s/${searchStr}/https:\/\/google.com:443/g" $line && echo "Sucessfully replaced $searchStr in $line"
        #Creating a payload file
        jq -n '{"status": "success","url" : "https://google.com:443"}' > payload.json
        #Making a POST call to dummy url with payload
        curl -s -X POST -H "Content-Type: application/json" -d @payload.json $localUrl > /dev/null
        if [ $? -eq 0 ]; then
            echo -e "Successfully uploaded payload to $localUrl"
        else
            echo -e "Connection cannot be established to $localUrl"
        fi
        echo -e ""    
    fi    
done < "$filelist"
if [ $counter -eq 0 ]; then 
    echo "$searchStr is not found in any file"
fi

#Checking if ansible package is installed and print the version if it is
if [ -x "$(command -v ansible)" >/dev/null 2>&1 ]; then
    vers=$(ansible --version | awk 'NR==1{print $2}')
    echo -e "Ansible $vers is installed"
else 
    echo -e "Ansible package is not installed in the system"
fi

echo -e "\nRemoving all contents"
cd .. && rm -rf $baseFolder


