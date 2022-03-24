#!/bin/sh

set -e

world_dir=/root/.minetest/worlds/world

echo "Preparing stage1: smoketests"
cp -R /stages/stage1 ${world_dir}/worldmods/stage1

cat << EOF > /minetest.conf
default_game = minetest_game
mg_name = v7
enable_integration_test = true
EOF

echo "Executing stage1"
minetestserver --config /minetest.conf

echo "Checking generated zip file"

ls -lha ${world_dir}

unzip -l ${world_dir}/stage1.zip