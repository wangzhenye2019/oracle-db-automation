#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
if grep -RInE '^[[:space:]]*[^#].*(password[[:space:]]*[:=]|BEGIN (RSA|OPENSSH) PRIVATE KEY|ghp_[A-Za-z0-9])' \
  --exclude-dir=.git --exclude='*.sh' .; then
  echo "Potential credential or secret found in tracked project files" >&2
  fail=1
fi

grep -q 'oracle_deploy_confirm: false' inventory/group_vars/oracle.example.yml
grep -q 'Require explicit deployment confirmation' playbooks/deploy_single_instance.yml
grep -q 'oracle_install_media_sha256' roles/oracle_precheck/tasks/main.yml
grep -q 'no_log: true' roles/oracle_database/tasks/main.yml
grep -q 'state: absent' roles/oracle_database/tasks/main.yml

test "$fail" -eq 0
echo 'Project safety checks passed.'
