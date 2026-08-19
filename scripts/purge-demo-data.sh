#!/bin/bash
# Amendment A1.1 — purge synthetic clinical records from the live database.
# KEEPS real configuration: wards, formulary, templateVersions, redFlagQuestions,
# functionalQuestions, invitations, meta, and all account collections.
# Run it yourself (destructive; needs your confirmation by running it):
#   bash scripts/purge-demo-data.sh
set -e
for c in patients handovers cases consents audit signInLog wellbeing practitioners; do
  echo "--- deleting collection: $c ---"
  firebase firestore:delete "$c" -r --force --project afia-12f38
done
echo "Done. Synthetic clinical records removed; configuration retained."
