#!/usr/bin/env bash
echo "Generating GitHub pages site from markdown"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR" || exit

echo " - Cleaning up site directory and copying spec-publisher site..."
git clean -f "$SCRIPT_DIR/specification/"
# git clean -f "$SCRIPT_DIR/site/"

if [ -d _site ]
then
  echo " - Removing old _site directory contents"
  rm -rf "$SCRIPT_DIR/_site/*"
fi

echo " - copying files to site directory..."
# Copy spec-publisher artifacts to the site
cp -rf "$SCRIPT_DIR/spec-publisher/site/"* "$SCRIPT_DIR/spec-publisher/res/md/figs" "$SCRIPT_DIR/site/"
# Copy remaining project collaterel to the site
if [ -d archive ]
then
  echo " - Copying archive content"
  cp -rf "$SCRIPT_DIR/archive/*" "$SCRIPT_DIR/site/"
fi

cp -rf "$SCRIPT_DIR/profile" "$SCRIPT_DIR/examples" "$SCRIPT_DIR/specification/figs" "$SCRIPT_DIR/site/"

echo " - spec-publisher: generating requirement tables, appendices, etc."
mvn package -f spec-publisher/pom.xml
java -jar "$SCRIPT_DIR/spec-publisher/target/mets-profile-processor-0.2.0-SNAPSHOT.jar" -f "$SCRIPT_DIR/specification.yaml" -o "$SCRIPT_DIR/specification" "$SCRIPT_DIR/profile/E-ARK-3DHM-ROOT_v1.0.0.xml" "$SCRIPT_DIR/profile/E-ARK-3DHM-REPRESENTATION_v1.0.0.xml"

echo " - Copying spec-publisher collateral to specification directory."
cp -rf "$SCRIPT_DIR/spec-publisher/res/md/common-intro.adoc" "$SCRIPT_DIR/spec-publisher/res/md/figs" "$SCRIPT_DIR/specification/"

echo " - Generating site HTML with asciidoctor."
asciidoctor -a linkcss -a copycss -e -o - "$SCRIPT_DIR/specification/E-ARK-CITS-3DHM.adoc" >> "$SCRIPT_DIR/site/index.html"

echo " - Generating site PDF with asciidoctor."
asciidoctor-pdf -o site/pdf/E-ARK-CITS-3DHM.pdf specification/E-ARK-CITS-3DHM.adoc

# echo " - Publishing site to GitHub Pages."
# docker run --rm -v "$PWD"/site:/usr/src/app -v "$PWD"/_site:/_site starefossen/github-pages jekyll build -d /_site

echo " - Cleaning up site directory and copying spec-publisher site..."
git clean -f "$SCRIPT_DIR/specification/"
git clean -f "$SCRIPT_DIR/site/"
