#!/bin/bash

# enable process protection on repo
function processRepo() {
  repo_name=$1
  main_branch=$2
  
  urlBranch="https://api.github.com/repos/${repo_name}/branches/${main_branch}"
  urlProtection="https://api.github.com/repos/${repo_name}/branches/${main_branch}/protection"
 
  isProtected=$(curl -s -u "lgmorand:$PAT" $urlBranch | jq .protected)
  
  if [ $isProtected == "false" ]; then
     curl -X PUT -u "lgmorand:$PAT" $urlProtection -H "Accept: application/vnd.github.v3+json"  -d '{"required_status_checks": null,"enforce_admins": null,"required_pull_request_reviews" : {"dismissal_restrictions": {},"dismiss_stale_reviews": false,"require_code_owner_reviews": true,"required_approving_review_count": 1},"restrictions":null}'
     echo "Protection has been added on $repo_name"
  fi
}

# List all repos
curl -u "lgmorand:$PAT" -H "Accept: application/vnd.github.v3+json" https://api.github.com/orgs/lgmorandOrg/repos | jq '[.[] | {"repo_name":.full_name, "main_branch": .default_branch}]' > repositories.json
cat repositories.json

# iterate on each repo
while read -r repo branch ; do
     processRepo ${repo} ${branch}
done< <( cat repositories.json | jq --raw-output '.[] | "\(.repo_name) \(.main_branch)"')

