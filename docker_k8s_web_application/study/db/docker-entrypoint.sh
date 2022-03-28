#! /bin/sh
INIT_FLAG_FILE=/data/db/init-completed
INIT_LOG_FILE=/data/db/init-mongod.log

start_mongod_as_daemon() {
echo 
echo "> start mongod ..."
echo 
mongod \
  --fork \ # daemon
  --logpath ${INIT_LOG_FILE} \
  --quiet \ # silences output from the shell during the connection process.
  --bind_ip 127.0.0.1 \ # mongod がバインド（listen）するIP
  --smallfiles;
}

create_user() {
echo
echo "> create user ..."
echo
if [ ! "$MONGO_INITDB_ROOT_USERNAME" ] || [ ! "$MONGO_INITDB_ROOT_PASSWORD" ]; then
  return
fi
mongo "${MONGO_INITDB_DATABASE}" <<-EOS
  db.createUser({
    user: "${MONGO_INITDB_ROOT_USERNAME}",
    pwd: "${MONGO_INITDB_ROOT_PASSWORD}",
    roles: [{ role: "root", db: "${MONGO_INITDB_DATABASE:-admin}"}]
  })
EOS
}

create_initialize_flag() {
echo
echo "> create initialize flag file ..."
echo
cat <<-EOF > "${INIT_FLAG_FILE}"
[$(date +%Y-%m-%dT%H:%M:%S.%3N)] Initialize scripts if finigshed.
EOF
}

stop_mongod() {
echo
echo "> stop mongod ..."
echo
mongod --shutdown
}

if [ ! -e ${INIT_FLAG_FILE} ]; then
  echo 
  echo "--- Initialize MongoDB ---"
  echo 
  start_mongod_as_daemon
  create_user
  create_initialize_flag
  stop_mongod
fi

exec "$@"