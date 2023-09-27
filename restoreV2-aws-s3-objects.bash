#!/bin/bash

# define a function for restoring a folder
function restore_folder {
    # first parameter is the bucket name
    bucket_name=$1
    # second parameter is the folder path
    folder_path=$2
    # third parameter is the number of days to restore
    restore_days=$3
    # fourth parameter is the dry run flag
    dry_run=$4

    # check if the dry run flag is set
    if [ "$dry_run" = "1" ]; then
        # echo with green color
        echo -e "\e[32mDry run mode\e[0m"
    fi

    # check if the folder exists
    if ! aws s3 ls "s3://$bucket_name/$folder_path" 2>&1 >/dev/null; then
        # echo with red color
        echo -e "\e[31mcheck:   Folder $folder_path does not exist\e[0m" >&2
        exit 1
    else 
        # echo with green color
        echo -e "\e[32mcheck:   Folder $folder_path exists\e[0m" >&2
    fi

    # check the folder size
    folder_size=$(aws s3 ls "s3://$bucket_name/$folder_path" --recursive | awk '{sum+=$3} END {print sum}')
    echo "Folder size: $folder_size" >&2

    # check the number of objects
    number_of_objects=$(aws s3 ls "s3://$bucket_name/$folder_path" --recursive | wc -l)
    echo "Number of objects: $number_of_objects" >&2

    # save the current delimiter
    OLDIFS=$IFS
    # user new line as delimiter
    IFS=$'\n'

    # objects=$(aws s3 ls "s3://$bucket_name/$folder_path" --recursive | awk '{print $4}')
    objects=$(aws s3 ls "s3://$bucket_name/$folder_path" --recursive | awk '{ for(i=4; i<=NF; i++) printf "%s%s", $i, (i<NF ? " " : "\n") }')

    for object in $objects; do
        # restore the objects
        if [ "$dry_run" = "1" ]; then
            echo "exec:    aws s3api restore-object --bucket $bucket_name --key \"$object\" --restore-request '{\"Days\":$restore_days, \"GlacierJobParameters\":{\"Tier\":\"Standard\"}}'" >&2
        else
            echo "exec:    aws s3api restore-object --bucket $bucket_name --key \"$object\" --restore-request '{\"Days\":$restore_days, \"GlacierJobParameters\":{\"Tier\":\"Standard\"}}'" >&2
            aws s3api restore-object --bucket "$bucket_name" --key "$object" --restore-request "{\"Days\":$restore_days, \"GlacierJobParameters\":{\"Tier\":\"Standard\"}}" >&2
        fi
    done

    # restore the original delimiter
    IFS=$OLDIFS
}

# inteligent parameters handling
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
POSITIONAL_ARGS=()
RESTORE_DAYS=3
while [[ $# -gt 0 ]]; do
    echo $POSITIONAL_ARGS
    key="$1"
    case $key in
        -d|--dry-run)
        DRY_RUN=1
        shift # past argument
        ;;
        -b|--bucket)
        BUCKET_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        -f|--folder)
        FOLDER_PATH="$2"
        shift # past argument
        shift # past value
        ;;
        -r|--restore-days)
        RESTORE_DAYS="$2"
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

# if the bucket name is not defined, exit
if [ -z "$BUCKET_NAME" ]; then
    # error with red color
    echo -e "\e[31mError:   Bucket name not provided\e[0m" >&2
    echo "Usage: $0 --bucket BUCKET_NAME --folder FOLDER_PATH [--dry-run]"
    exit 1
else
    # check with green color
    echo -e "\e[32mInfo:    Bucket name $BUCKET_NAME provided\e[0m" >&2
fi

# check if is any data in stdin
# https://stackoverflow.com/questions/911168/how-to-detect-if-my-shell-script-is-running-through-a-pipe
if [ -t 0 ]; then
    # warning with yellow color
    echo -e "\e[33mWarning: no data in stdin\e[0m" >&2 
else
    # process from stdin with green color
    echo -e "\e[32mInfo:    Processing folders from stdin\e[0m" >&2
    # https://stackoverflow.com/questions/21620406/read-stdin-line-by-line-in-bash-script
    while read line; do
        if [ -z "$line" ]; then
            continue
        fi
        # execute the restore command
        restore_folder "$BUCKET_NAME" "$line" "$RESTORE_DAYS" "$DRY_RUN"
    done
    exit 0
fi

# if the folder path is not defined, exit
if [ -z "$FOLDER_PATH" ]; then
    # error with red color
    echo -e "\e[31mError:   Folder path not provided\e[0m" >&2
    echo "Usage: $0 --bucket BUCKET_NAME --folder FOLDER_PATH [--dry-run]"
    exit 1
fi

# execute the restore command
restore_folder "$BUCKET_NAME" "$FOLDER_PATH" "$RESTORE_DAYS" "$DRY_RUN"
