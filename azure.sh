##################################################  variables ##################################################
organization=$azure_organization
project=$azure_project
password=$AZP_TOKEN

##################################################  methods ##################################################

# $1 = url
# $2 = filename
# $3 = header
# $4 = mapping
get() {
  # get json data
  curl --silent --user ":$password" --request GET $1 | jq . >output/$2.json
  # create csv file with header
  echo $3 >output/$2.csv
  # append data to csv file
  jq "." output/$2.json | jq -r "$4 | @csv" >>output/$2.csv
}

##################################################  init ##################################################

clear
mkdir -p output
# rm -rf output/*

##################################################  query ##################################################

# projects => https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/list
get "https://dev.azure.com/$organization/_apis/projects" "projects" "id,name" ".value[] | [.id,.name]"

# pipelines => https://learn.microsoft.com/en-us/rest/api/azure/devops/pipelines/pipelines/list

get "https://dev.azure.com/$organization/$project/_apis/pipelines" "pipelines" "id,name,folder,url" ".value[] | [.id,.name,.folder,.url]"
