connector_plugin="${args[--connector-plugin]}"
connector_tag="${args[--connector-tag]}"
class="${args[--class]}"


if [[ $connector_plugin == *"@"* ]]
then
  connector_plugin=$(echo "$connector_plugin" | cut -d "@" -f 2)
fi

tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
trap 'rm -rf $tmp_dir' EXIT

log "🔌 Downloading connector plugin $connector_plugin:$connector_tag"
docker run -u0 -i --rm -v $tmp_dir:/usr/share/confluent-hub-components ${CP_CONNECT_IMAGE}:${CONNECT_TAG} bash -c "confluent-hub install --no-prompt $connector_plugin:$connector_tag && chown -R $(id -u $USER):$(id -g $USER) /usr/share/confluent-hub-components" | grep "Downloading"

log "♨️ Listing jar files"
cd $tmp_dir/*/lib
ls -1 | sort

if [[ -n "$class" ]]
then
  log "Searching for java class $class in all jars"
  find . -name '*.jar' -print | while read i; 
  do 
    set +e
    jar -tvf "$i" | grep -Hsi ${class} | awk '{print $10}' | sed 's/\.class$//' | tr '/' '.' | while read j
    do
      if [ $? -eq 0 ]
      then
        if [ "$j" != "" ]
        then
          log "👉 method signatures from $i jar for class $j"
          javap -classpath $i $j
        fi
      fi
    done
  done
fi