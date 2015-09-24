#!/bin/bash

set -e

CONFIG=/data/config.json

get_config() {
  key="$1"
  value=`jsawk "if (this.$key && this.$key != 'FIXME') { return this.$key; } else { return null; }" <"$CONFIG"`
  if [ $? -eq 0 ]; then
    echo "$value"
  else
    echo "Error querying config key '$key'" >&2
    exit 1
  fi
}

set_config() {
  key="$1"
  value="$2"
  c=/data/config.json
  if (jsawk "this.$key = $value;" <"$CONFIG" | pp > "$CONFIG.tmp"); then
    mv "${c}.tmp" "$CONFIG"
  else
    echo "config modification for key '$key' failed!" >&2
    exit 1
  fi
}

generate_salt() {
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 48 | head -n 1
}

mkdir -p web/static/js

# TODO: create database?

if [ ! -f /data/config.json ]; then
  echo "Copying default config to '$CONFIG'"
  cp /mattermost/config.default.json "$CONFIG"
fi

if [ "$DATABASE_DSN" ]; then
  ds="SqlSettings.DataSource"
  if [ "`get_config "$ds"`" != "$DATABASE_DSN" ]; then
    echo "Updating database DSN..."
    set_config "$ds" "'$DATABASE_DSN'"
  fi
  dr="SqlSettings.DataSourceReplicas"
  if [ "`get_config "$dr[0]"`" != "$DATABASE_DSN" ]; then
    echo "Updating database DSN in replicas..."
    set_config "$dr[0]" "'$DATABASE_DSN'"
  fi
fi

# encryption settings
for key in \
  ServiceSettings.InviteSalt \
  ServiceSettings.PublicLinkSalt \
  ServiceSettings.ResetSalt \
  SqlSettings.AtRestEncryptKey
do
  if [ -z `get_config "$key"` ]; then
    echo "Generating and setting salt for '$key'..."
    set_config "$key" "'`generate_salt`'"
  fi
done

# ensure ownership of data
if [ `stat -c %U /data` != "mattermost" ]; then
  echo "Changing ownership of /data"
  chown -R mattermost /data
fi

# create log dir
if [ ! -d /data/logs ]; then
  mkdir /data/logs
  chown mattermost /data/logs
fi

exec "$@"
