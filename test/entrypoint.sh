#!/bin/sh

set -e

world_dir=/root/.minetest/worlds/world

cp -R /stages/stage1 ${world_dir}/worldmods/stage1

cat << EOF > /minetest.conf
default_game = minetest_game
mg_name = v7
enable_integration_test = true
EOF

minetestserver --config /minetest.conf

echo "Checking generated zip file"

ls -lha ${world_dir}
test -f ${world_dir}/stage1.zip

hexdump -Cv ${world_dir}/stage1.zip
unzip -l ${world_dir}/stage1.zip

unzip ${world_dir}/stage1.zip

test -f test.txt
contents=$(cat test.txt)
test "${contents}" == "abcdefghijklmnopqrstuvwxyz"