for d in ../Sources/AWSSDKSwift/Services/*;
  do moduleName="$(basename "$d")";
  sourcekitten doc --spm-module $moduleName > "$moduleName".json;
done;
jq -s '[.[][]]' *.json > awssdkswift.json;
ls | grep "^[A-Z].*.json" | xargs rm -f
jazzy --theme ../jazzy/themes/apple-thin-nav/
# use theme apple-thin-nav else docs are 50+ GB!
rm -rf docs/docsets
# then
# move /docs contents to gh-pages branch
