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
  # # create json file
  # curl --silent --user ":$password" --request GET $1 | jq . >output/azure/$2.json

  # create csv file
  echo $3 >output/azure/$2.csv
  jq "." output/azure/$2.json | jq -r "$4 | @csv" >>output/azure/$2.csv

  # create markdown file
  echo "|${3//,/|}|" >output/azure/$2.md
  echo "$3" | sed -e 's/[^,]*/--/g' -e 's/[,]/|/g' | awk '{print "|"$0"|"}' >>output/azure/$2.md
  jq "." output/azure/$2.json | jq -r "$5" >>output/azure/$2.md
}

##################################################  init ##################################################

clear
mkdir -p output/azure
# rm -rf output/*

##################################################  query ##################################################

# projects => https://learn.microsoft.com/en-us/rest/api/azure/devops/core/projects/list
get "https://dev.azure.com/$organization/_apis/projects" "projects" \
  "id,name" \
  ".value[] | [.id,.name]" \
  ".value[] | \"|\(.id)|\(.name)|\""

# pipelines => https://learn.microsoft.com/en-us/rest/api/azure/devops/pipelines/pipelines/list
get "https://dev.azure.com/$organization/$project/_apis/pipelines" "pipelines" \
  "id,name,folder,url" \
  ".value[] | [.id,.name,.folder,.url]" \
  ".value[] | \"|\(.id)|\(.name)|\(.folder)|\(.url)|\""
