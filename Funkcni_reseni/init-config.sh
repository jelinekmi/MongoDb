#!/bin/bash

set -e

wait_for_mongo() {
  echo " čekám na $1..."
  until mongosh "mongodb://$1" --eval "db.adminCommand({ ping: 1 })" > /dev/null 2>&1; do
    sleep 2
  done
  echo "? $1 je dostupný."
}

# Načíst .env proměnné (pokud existují)
if [ -f "./.env" ]; then
  source ./.env
fi

# Pokud je AUTH zapnutý, nic neinicializujeme
if [ "$AUTH" = "enabled" ]; then
  exit 0
fi

# čekáme na dostupnost všech config serverù
wait_for_mongo "configsvr1:27019"
wait_for_mongo "configsvr2:27019"
wait_for_mongo "configsvr3:27019"

# Inicializace replikačního setu config serverů
mongosh "mongodb://configsvr1:27019" <<'EOF'
try {
  const status = rs.status();
} catch (e) {
  if (e.code === 94 || e.codeName === 'NotYetInitialized') {
    rs.initiate({
      _id: "cfgRS",
      configsvr: true,
      members: [
        { _id: 0, host: "configsvr1:27019" },
        { _id: 1, host: "configsvr2:27019" },
        { _id: 2, host: "configsvr3:27019" }
      ]
    });
  } else {
    quit(1);
  }
}
EOF

