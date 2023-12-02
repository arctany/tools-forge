#!/bin/bash

# Video formats
video_formats=("mp4" "TS" "ts" "mkv" "avi" "flv" "mov" "wmv" "rm" "rmvb" "mpeg" "3gp" "webm" "vob" "m4v" "3g2" "ogv" "m4p" "mpv" "mpg")

# Change IFS to fix issues with spaces in the file names
IFS=$'\n'

# Function to print total size of all files in a directory
print_total_size() {
    dir=$1
    total_size=0
    for file in $(find "$dir" -type f -not -path '*/\.*'); do
        filename=$(basename "$file")
        extension="${filename##*.}"
        if [[ " ${video_formats[@]} " =~ " ${extension} " ]]; then
            file_size=$(stat -c%s "$file")
            total_size=$(($total_size + $file_size))
        fi
    done
    total_size_byte=$(echo "$total_size")
        printf "%90s" "${total_size_byte} byte."
}

# Search videos
search_videos() {
    debug=$1
    directory=$2
    min_size=$3
    max_size=$4

    # Convert MB to bytes
    min_size_bytes=$(($min_size * 1024 * 1024))
    max_size_bytes=$(($max_size * 1024 * 1024))

    for dir in $(find "$directory" -maxdepth 1 -type d ! -path '*/.*'); do
        all_files_meet_criteria=true
        for file in $(find "$dir" -type f -not -path '*/\.*'); do
            filename=$(basename "$file")
            extension="${filename##*.}"
            if [[ " ${video_formats[@]} " =~ " ${extension} " ]]; then
                file_size=$(stat -c%s "$file")
                if [ $file_size -lt $min_size_bytes ]; then
                    all_files_meet_criteria=false
                    if $debug; then
                        echo "File '$filename' is smaller than the minimum size of ${min_size}MB."
                    fi
                    break
                fi
                if [ $file_size -gt $max_size_bytes ]; then
                    all_files_meet_criteria=false
                    if $debug; then
                        echo "File '$filename' is larger than the maximum size of ${max_size}MB."
                    fi
                    break
                fi
            fi
        done
        if $all_files_meet_criteria ; then
            echo -n "\"${directory}$(basename "$dir")\"";print_total_size $dir;echo ''
            if ! -z $dest; then
              echo " move $(basename "$dir") to $dest "
              mv $(basename "$dir") $dest;
        fi
    done
}

# Parse command line arguments
while getopts ":d:m:M:Dh" opt; do
  case ${opt} in
    d)
      directory=$OPTARG
      ;;
    m)
      min_size=$OPTARG
      ;;
    M)
      max_size=$OPTARG
      ;;
    D)
      debug=true
      ;;
    r)
      dest=$OPTARG
      ;;
    h)
      echo "Usage: $0 -d directory -m min_size -M max_size [-D] [-h]"
      echo "Search video files in the given directory and its subdirectories."
      echo "  -d   directory to search"
      echo "  -m   minimum file size in MB"
      echo "  -M   maximum file size in MB"
      echo "  -D   debug mode"
      echo "  -h   display this help message"
      echo "  -r   dest dir to move "
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" 1>&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." 1>&2
      exit 1
      ;;
  esac
done

# Check if the required arguments are provided
if [ -z "$directory" ] || [ -z "$min_size" ] || [ -z "$max_size" ]; then
    echo "Missing required arguments. Use -h for help." 1>&2
    exit 1
fi

# Set debug mode to false if not set
if [ -z "$debug" ]; then
    debug=false
fi

# Call the function
search_videos $debug "$directory" $min_size $max_size