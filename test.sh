#!/bin/bash

do_test(){
  for i in {1..5000}; do
    curl \
      --silent \
      -I \
      -H 'Host: meshblu-http.octoblu.com' \
      http://b0256109-b669-49f2-8f07-ce8fa478b0be:1c73db665a68eac7342dbfbca51530816d57ce5b@meshblu-http.octoblu.com/v2/whoami
  done
}

do_test | tee output.txt | grep --line-buffered 'HTTP/' | pv -l -s 5000 | grep --line-buffered -v '200'
