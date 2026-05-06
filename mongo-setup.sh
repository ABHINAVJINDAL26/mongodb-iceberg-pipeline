#!/bin/bash
set -e

KEYFILE="/data/db/mongo-keyfile"

echo "==> Phase 1: Starting MongoDB without auth for initialization..."
mongod --replSet rs0 --bind_ip_all --port 27017 &
MONGOD_PID=$!

echo "==> Waiting for MongoDB to be ready..."
until mongosh --quiet --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
    sleep 2
done
echo "==> MongoDB is ready!"

echo "==> Initializing replica set..."
mongosh --quiet --eval "
  try {
    rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'mongo1:27017'}]});
    print('Replica set initiated');
  } catch(e) {
    print('RS init: ' + e);
  }
"

echo "==> Waiting for primary election..."
sleep 5

echo "==> Creating admin user..."
mongosh admin --quiet --eval "
  try {
    db.createUser({
      user: 'admin',
      pwd: 'password',
      roles: [{role: 'root', db: 'admin'}]
    });
    print('Admin user created');
  } catch(e) {
    print('User creation: ' + e);
  }
"

echo "==> Shutting down temporary mongod..."
mongosh admin --quiet --eval "db.adminCommand({shutdown: 1, force: true})" || true
wait $MONGOD_PID 2>/dev/null || true

echo "==> Generating keyFile..."
openssl rand -base64 756 > "$KEYFILE"
chmod 400 "$KEYFILE"

echo "==> Phase 2: Restarting MongoDB with auth + keyFile..."
exec mongod --replSet rs0 --bind_ip_all --port 27017 --auth --keyFile "$KEYFILE"
