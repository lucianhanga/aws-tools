#!/bin/bash

# inteligent parameters handling
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

POSITIONAL_ARGS=()
FOLDERS=0
while [[ $# -gt 0 ]]; do
    # echo $POSITIONAL_ARGS
    key="$1"
    case $key in
        -b | --bucket)
        BUCKET="$2"
        shift # past argument
        shift # past value
        ;;
        *)    # unknown option
        POSITIONAL_ARGS+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# check if the bucket was provided
if [ -z "$BUCKET" ]; then
    # show error with red color
    echo -e "\e[31mError:   Bucket name not provided\e[0m"
    # show usage for both forms
    echo "Usage: ./listV2-aws-s3-folders.bash --bucket BUCKET"
    exit 1
fi

# check if the bucket exists
if ! aws s3api head-bucket --bucket "$BUCKET" 2>&1 >/dev/null; then
    # echo with red color
    # echo on stderr
    echo -e "\e[31mcheck:   Bucket $BUCKET does not exist\e[0m" >&2
    exit 1
else 
    # echo with green color
    echo -e "\e[32mcheck:   Bucket $BUCKET exists\e[0m" >&2
fi

# save the current delimiter
OLDIFS=$IFS
# user new line as delimiter
IFS=$'\n'

folders=$(aws s3 ls s3://$BUCKET | awk '{ for(i=2; i<=NF; i++) printf "%s%s", $i, (i<NF ? " " : "\n") }')
for folder in $folders; do
    # check if its an object or folder
    if [ ${folder: -1} == "/" ]; then
        echo "$folder"
    fi
done

# restore the original delimiter
IFS=$OLDIFS
