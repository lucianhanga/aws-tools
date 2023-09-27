#!/bin/bash

# inteligent parameters handling
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

# optional parameter for listing the subfolders of the bucket
POSITIONAL_ARGS=()
FOLDERS=0
while [[ $# -gt 0 ]]; do
    # echo $POSITIONAL_ARGS
    key="$1"
    case $key in
        -f | --folders)
        FOLDERS=1
        shift # past argument
        ;;
        *)    # unknown option
        POSITIONAL_ARGS+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# display the value of the optional parameter
# echo "Show folders = ${FOLDERS}"
if [ $FOLDERS -eq 1 ]; then
    echo "INFO: display also the folders from the bucket"
fi


# save the current delimiter
OLDIFS=$IFS
# user new line as delimiter
IFS=$'\n'

# list all the buckets in an list
buckets=$(aws s3 ls | awk '{print $3}')

# # simmulate a list of buckets - for testing
# buckets_source="test-pictures-backup\ntest-pictures-backup2\nmomo momo"
# buckets=$(echo -e $buckets_source)

for bucket in $buckets; do
    echo $bucket
    # list all the folders in the bucket take in account the _spaces_ in the names
    folders=$(aws s3 ls s3://$bucket | awk '{ for(i=2; i<=NF; i++) printf "%s%s", $i, (i<NF ? " " : "\n") }')
    for folder in $folders; do
        # check if its an object or folder
        if [ ${folder: -1} == "/" ]; then
            # its a folder
            if [ $FOLDERS -eq 1 ]; then
                echo "$folder"
            fi
        fi
    done
done

# restore the original delimiter
IFS=$OLDIFS
