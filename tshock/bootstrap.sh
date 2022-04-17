#!/bin/sh

echo "\nBootstrap:\nworld_file_name=$WORLD_FILENAME\nconfigpath=$CONFIGPATH\nlogpath=$LOGPATH\nconfigURL=$CONFIG_URL"
echo "Copying plugins..."
cp -Rfv /plugins/* ./ServerPlugins
curl -o $CONFIGPATH/config.json -L $CONFIG_URL
curl -o $CONFIGPATH/sscconfig.json -L $SSC_CONFIG_URL
STORAGETYPE=$(cat $CONFIGPATH/config.json | jq -r '.StorageType')
if [ $STORAGETYPE = "mysql" ]; then
  DATABASE_SERVER=$(cat $CONFIGPATH/config.json | jq -r '.MySqlHost' | cut -f1 -d':')
  DATABASE_PORT=$(cat $CONFIGPATH/config.json | jq -r '.MySqlHost' | cut -f2 -d':')
  DATABASE_USER_NAME=$(cat $CONFIGPATH/config.json | jq -r '.MySqlUsername')
  DATABASE_USER_PASSWORD=$(cat $CONFIGPATH/config.json | jq -r '.MySqlPassword')
  echo "Waiting for the database server."
  while ! mysql -h$DATABASE_SERVER -P$DATABASE_PORT -u$DATABASE_USER_NAME -p$DATABASE_USER_PASSWORD  -e ";" ; do
    sleep 0.1;
  done
fi

WORLD_PATH="/worlds/$WORLD_FILENAME"

if [ -z "$WORLD_FILENAME" ]; then
  echo "No world file specified in environment WORLD_FILENAME."
  if [ -z "$@" ]; then 
    echo "Running server setup..."
  else
    echo "Running server with command flags: $@"
  fi
  mono --server --gc=sgen -O=all TerrariaServer.exe -configpath "$CONFIGPATH" -logpath "$LOGPATH" -disable-commands "$@" 
else
  echo "Environment WORLD_FILENAME specified"
  if [ -f "$WORLD_PATH" ]; then
    echo "Loading to world $WORLD_FILENAME..."
    mono --server --gc=sgen -O=all TerrariaServer.exe -configpath "$CONFIGPATH" -logpath "$LOGPATH" -world "$WORLD_PATH" -disable-commands "$@" 
  else
    echo "Unable to locate $WORLD_PATH.\nPlease make sure your world file is volumed into docker: -v <path_to_world_file>:/root/.local/share/Terraria/Worlds"
    exit 1
  fi
fi
