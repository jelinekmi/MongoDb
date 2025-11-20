#!/bin/bash

# Načtení proměnných z .env
if [ -f "./.env" ]; then
  source ./.env
fi

set -e

wait_for_mongo() {
  echo " čekám na $1..."
  until mongosh "mongodb://$1" --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
    sleep 2
  done
  echo "? $1 je dostupný."
}
echo ">> AUTH=$AUTH"
if [ "$AUTH" = "enabled" ]; then
   exit 0
fi

wait_for_mongo "mongos-router:27017"

wait_for_mongo "shard1a:27101"
wait_for_mongo "shard1b:27102"
wait_for_mongo "shard1c:27103"
wait_for_mongo "shard2a:27201"
wait_for_mongo "shard2b:27202"
wait_for_mongo "shard2c:27203"
wait_for_mongo "shard3a:27301"
wait_for_mongo "shard3b:27302"
wait_for_mongo "shard3c:27303"

# shard1
mongosh "mongodb://shard1a:27101" <<EOF
try {
  rs.initiate({
    _id: "shard1",
    members: [
      { _id: 0, host: "shard1a:27101", priority: 2 },
      { _id: 1, host: "shard1b:27102", priority: 1 },
      { _id: 2, host: "shard1c:27103", priority: 1 }
    ]
  });
} catch(e) { print(e); }
EOF

# shard2
mongosh "mongodb://shard2a:27201" <<EOF
try {
  rs.initiate({
    _id: "shard2",
    members: [
      { _id: 0, host: "shard2a:27201", priority: 2 },
      { _id: 1, host: "shard2b:27202", priority: 1 },
      { _id: 2, host: "shard2c:27203", priority: 1 }
    ]
  });
} catch(e) { print(e); }
EOF

# shard3
mongosh "mongodb://shard3a:27301" <<EOF
try {
  rs.initiate({
    _id: "shard3",
    members: [
      { _id: 0, host: "shard3a:27301", priority: 2 },
      { _id: 1, host: "shard3b:27302", priority: 1 },
      { _id: 2, host: "shard3c:27303", priority: 1 }
    ]
  });
} catch(e) { print(e); }
EOF

mongosh "mongodb://mongos-router:27017" <<EOF
sh.addShard("shard1/shard1a:27101,shard1b:27102,shard1c:27103");
sh.addShard("shard2/shard2a:27201,shard2b:27202,shard2c:27203");
sh.addShard("shard3/shard3a:27301,shard3b:27302,shard3c:27303");

db = db.getSiblingDB("mydb");
sh.enableSharding("mydb");

db.createCollection("Products", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["product_id", "product_category_name", "product_weight_g", "product_length_cm", "product_height_cm", "product_width_cm"],
      properties: {
        product_id: { bsonType: "string" },
        product_category_name: { bsonType: "string" },
        product_weight_g: { bsonType: ["int", "double"] },
        product_length_cm: { bsonType: ["int", "double"] },
        product_height_cm: { bsonType: ["int", "double"] },
        product_width_cm: { bsonType: ["int", "double"] }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});
db.Products.createIndex({ product_id: "hashed" });
sh.shardCollection("mydb.Products", { product_id: "hashed" });

db.createCollection("Orders", {
  validator: {
    \$jsonSchema: {
      bsonType: "object",
      required: ["order_id", "customer_id", "order_purchase_timestamp", "order_approved_at"],
      properties: {
        order_id: { bsonType: "string" },
        customer_id: { bsonType: "string" },
        order_purchase_timestamp: { bsonType: "string" },
        order_approved_at: { bsonType: "string" }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});
db.Orders.createIndex({ order_id: "hashed" });
sh.shardCollection("mydb.Orders", { order_id: "hashed" });

db.createCollection("OrderItems", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["order_id", "product_id", "seller_id", "price", "freight_value"],
      properties: {
        order_id: { bsonType: "string" },
        product_id: { bsonType: "string" },
        seller_id: { bsonType: "string" },
        price: { bsonType: "double" },
        freight_value: { bsonType: "double" }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});
db.OrderItems.createIndex({ order_id: "hashed" });
sh.shardCollection("mydb.OrderItems", { order_id: "hashed" });
EOF


mongosh "mongodb://mongos-router:27017/admin" <<EOF
if (!db.getUser("admin")) {
  db.createUser({
    user: "admin",
    pwd: "admin",
    roles: [ { role: "root", db: "admin" } ]
  });
}
EOF

for host in shard1a:27101 shard2a:27201 shard3a:27301; do
   mongosh "mongodb://$host/admin" <<EOF
if (!db.getUser("admin")) {
  db.createUser({
    user: "admin",
    pwd: "admin",
    roles: [ { role: "root", db: "admin" } ]
  });
}
EOF
done




