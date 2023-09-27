#!/bin/bash

# intelligent parameters handling
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    echo $POSITIONAL_ARGS
    key="$1"
    case $key in
        --folder)
        FOLDER_PATH="$2"
        shift # past argument
        shift # past value
        ;;
        --dry-run)
        DRY_RUN=1
        shift # past argument
        ;;
        *)    # unknown option
        POSITIONAL_ARGS+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# check if the paramreters are provided
if [ -z "$FOLDER_PATH" ]; then
    # error with red color
    echo -e "\e[31mError:   Folder path not provided\e[0m" >&2
    echo "Usage: $0 --folder FOLDER_PATH [--dry-run]"
    exit 1
else
    # check with green color
    echo -e "\e[32mInfo:    Folder path $FOLDER_PATH provided\e[0m" >&2
fi

# get all the files in the folder in a list
# https://stackoverflow.com/questions/23356779/recursive-file-list-in-bash


# use as delimiter only the new line
OLDIFS=$IFS
IFS=$'\n'
folders=$(ls -l $FOLDER_PATH | awk '{ for(i=9; i<=NF; i++) printf "%s%s", $i, (i<NF ? " " : "\n") }')
# echo $folders
# change the working directory
cd $FOLDER_PATH > /dev/null
for folder in $folders; do
    # echo $folder
    # check if its folder or file
    if [ -d "$folder" ]; then
        # its a folder, echo with green color
        echo -e "\e[32mInfo:    $folder is a folder\e[0m" >&2
        # zip it with the same name and add all its content
        if [ "$DRY_RUN" = "1" ]; then
            echo "exec:    zip -r $folder.zip $folder" >&2
        else
            echo "exec:    zip -r $folder.zip $folder" >&2
            # call zip with verbose
            zip -r $folder.zip $folder
        fi
    else
        # its a file, ingore with yellow color
        echo -e "\e[33mWarning: $folder is a file\e[0m" >&2
    fi
done
# back to the original working directory
cd - > /dev/null
# restore the original delimiter
IFS=$OLDIFS


