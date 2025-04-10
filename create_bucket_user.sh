#! /bin/bash

name="k8s-$1"
password=$(pwgen -s 50 1)

function clean_up() {
  echo -n "Something went wrong, do you want to delete all created objects? [y/N]  "
  read yn
  if [ $yn == "y" ] ; then
    mc rb $name
    mc admin user rm $name
    mc admin policy rm $name
  fi
  exit 1
}


mc mb "tn/$name" || clean_up
mc admin user add tn "$name" "$password" || clean_up

tmp_policy_file="/tmp/minio-policy-$RANDOM.json"
cat > "$tmp_policy_file" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::$name/*",
        "arn:aws:s3:::$name"
      ]
    }
  ]
}
EOF

mc admin policy create tn "$name" "$tmp_policy_file" || clean_up
mc admin policy attach tn "$name" --user $name || clean_up

rm "$tmp_policy_file"

echo "Password: $password"
