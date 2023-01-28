#!/bin/bash

pushd /root || exit

echo Running supervisord in the background
# cd /root || exit
/usr/bin/supervisord --configuration supervisord.conf &

popd || exit




wait_available() {

  RETRIES=60
  WAIT_DIR="$1"

  while [ $RETRIES -gt 0 ];
  do
    RETRIES=$((RETRIES - 1))

    OUTPUT=$(adb shell ls -d "$WAIT_DIR" 2> /dev/null)

    if [ "$OUTPUT" == "$WAIT_DIR" ]
    then
      break;
    fi
    sleep 1

  done

  if [ $RETRIES -le 0 ]
  then
    echo "Emulator directory $1 was not available, exiting"
    exit 1
  fi

}

echo Checking readiness via adb shell ls -d /sdcard/Android
wait_available /sdcard/Android

mkdir -p /adbfs
/usr/bin/adbfs /adbfs

echo Ready to run adbfs tests

BASE_DIR=/adbfs/sdcard/test

test_mkdir() {

  local_timestamp=$(date "+%s")

  mkdir "$BASE_DIR/x"
  output=$(ls -lad --time-style="+%s" "$BASE_DIR/x")

  timestamp=$(echo $output | cut -d' ' -f 6)
  path=$(echo $output | cut -d' ' -f 7)

  timestamp_diff=$((local_timestamp - timestamp))
  abs_diff=${timestamp_diff#-}

  if [ "$abs_diff" -gt 120 ];
  then
    echo "FAIL test_mkdir: file timestamp difference exceeds 120s: $abs_diff"
    exit 1
  fi

  if [ "$path" != "$BASE_DIR/x" ];
  then
    echo "FAIL test_mkdir: unexpected path"
    exit 1
  fi

  echo "PASS test_mkdir"
}


test_catfile() {

  local_timestamp=$(date "+%s")

  desired_content="Hello world"

  echo "$desired_content" > "$BASE_DIR/file.txt"

  output=$(ls -lad --time-style="+%s" "$BASE_DIR/file.txt")

  timestamp=$(echo $output | cut -d' ' -f 6)
  path=$(echo $output | cut -d' ' -f 7)

  timestamp_diff=$((local_timestamp - timestamp))
  abs_diff=${timestamp_diff#-}

  if [ "$abs_diff" -gt 120 ];
  then
    echo "FAIL test_catfile: file timestamp difference exceeds 120s: $abs_diff"
    exit 1
  fi

  if [ "$path" != "$BASE_DIR/file.txt" ];
  then
    echo "FAIL test_catfile: unexpected path"
    exit 1
  fi

  file_contents=$(cat $BASE_DIR/file.txt)

  if [ "$file_contents" != "Hello world" ]
  then
    echo "FAIL test_catfile: unexpected content: $file_contents"
    echo "Expected: $desired_content"
    exit 1
  fi

  echo "PASS test_catfile"
}



mkdir "$BASE_DIR"

test_mkdir
test_catfile

# todo

# copy file with cp -a (archive, preserve timestamps)

# read a directory

# touch to update time

# copy preserving timestamps

rm -rf "$BASE_DIR"



# rsync, both directions (compared against rsync of the very same tree on a "pure local" FS).
# ompared to adb push --sync as well maybe

