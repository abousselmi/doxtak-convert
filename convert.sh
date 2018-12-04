#!/bin/bash

#
# convert.sh converts all files into markdown before the doxtak build
# Eg. RST -> MD or YML -> MD
#

echo "******* Start convert"

function log {
  echo -e `date +%Y/%m/%d\ %X`" (convert) - $1" > /dev/stdout
}

function logerr {
  >&2 echo `date +%Y/%m/%d\ %X`" (convert) - $1" > /dev/stderr
}

# check the setup
if [[ -z "${S2M_CLI_PATH}" ]]; then
  logerr "S2M_CLI_PATH is not defined. Please locate the cli.jar"
  exit 1
else
  log "checking configuration - $S2M_CLI_PATH"
fi

if [[ -z "${DATA_DIR}" ]]; then
  logerr "DATA_DIR is not defined. Please locate the source data dir"
  exit 1
else
  log "checking configuration - $DATA_DIR"
fi

EXT_LIST_MARKUP="rst html"

# check if the file is a markup other than markdown
function is_markup {
  x=`echo $1 | awk -F . '{print $NF}'`
  [[ $EXT_LIST_MARKUP =~ (^| )$x($| ) ]] && echo 'yes' || echo 'no'
}

# check if the file is a markdown
function is_markdown {
  x=`echo $1 | awk -F . '{print $NF}'`
  [[ "md" =~ (^| )$x($| ) ]] && echo 'yes' || echo 'no'
}

EXT_LIST_IMAGE="png jpg jpeg gif bmp"

# check if the file is an image
function is_image {
  x=`echo $1 | awk -F . '{print $NF}'`
  [[ $EXT_LIST_IMAGE =~ (^| )$x($| ) ]] && echo 'yes' || echo 'no'
}

EXT_LIST_SWAGGER="yaml yml"

# check if the file is swagger
function is_swagger {
  x=`echo $1 | awk -F . '{print $NF}'`
  [[ $EXT_LIST_SWAGGER =~ (^| )$x($| ) ]] && echo 'yes' || echo 'no'
}

# if document convert else if image do nothing else print unkown
function batch_processing {
  for docfile in "$@" ; do
    filename="${docfile%.*}"

    # markdown
    if [[ `is_markdown $docfile` == "yes" ]] ; then
      log "$docfile is already in markdown. passing ..."

    # markup
    elif [[ `is_markup $docfile` == "yes" ]] ; then
      log "pandoc: converting $docfile ..."
      /usr/bin/pandoc $docfile -o $filename.md > /dev/null
      #rm -rf $docfile

    # image
    elif [[ `is_image $docfile` == "yes" ]] ; then
      log "$docfile is an image file. passing ..."

    # swagger
    elif [[ `is_swagger $docfile` == "yes" ]];  then
      log "swagger: converting $docfile ..."
      /usr/bin/java \
        -jar $S2M_CLI_PATH/cli.jar convert \
          -i $docfile \
          -c $S2M_CLI_PATH/config.properties \
          -d ./$filename \
        > /dev/null
      #rm -rf $docfile

    # other
    else
      logerr "unknown file extension: $docfile. deleting ..."
      #rm -rf $docfile
    fi
  done
}

# convert file in the data dir
function convert {
  log "moving to $1"
  cd $1
  log "begin converting ..."
  files=`find -type f | xargs -r -d '\n' echo` && batch_processing $files
  log "done."
}

# Main
convert $DATA_DIR