#!/usr/bin/env bash
echo "Generating GitHub pages site from markdown"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR" || exit

echo " - Cleaning up site directory and copying spec-publisher site..."
git clean -f "$SCRIPT_DIR/specification/"
git clean -f "$SCRIPT_DIR/site/"

if [ -d _site ]
then
  echo " - Removing old _site directory contents"
  rm -rf "$SCRIPT_DIR/_site/*"
fi

echo " - copying files to site directory..."
# Copy spec-publisher artifacts to the site
cp -rf "$SCRIPT_DIR/spec-publisher/site/"* "$SCRIPT_DIR/spec-publisher/res/md/figs" "$SCRIPT_DIR/site/"
# Copy remaining project collaterel to the site
cp -rf "$SCRIPT_DIR/profile" "$SCRIPT_DIR/examples" "$SCRIPT_DIR/specification/figs" "$SCRIPT_DIR/pdf" "$SCRIPT_DIR/site/"

echo " - spec-publisher: generating specification requirement tables, appendices, etc."
mvn package -f spec-publisher/pom.xml 
java -jar "$SCRIPT_DIR/spec-publisher/target/mets-profile-processor-0.2.0-SNAPSHOT.jar" \
     -f "$SCRIPT_DIR/specification.yaml" \
     -o "$SCRIPT_DIR/specification" \
     profile/E-ARK-3DHM-ROOT_v1.0.0.xml "profile/E-ARK-3DHM-REPRESENTATION_v1.0.0.xml"

echo " - Copying spec-publisher collateral to specification directory."
cp -rf "$SCRIPT_DIR/spec-publisher/res/md/common-intro.adoc" "$SCRIPT_DIR/spec-publisher/res/md/figs" "$SCRIPT_DIR/specification/"

echo " - Generating specification HTML with asciidoctor."
asciidoctor -a linkcss -a copycss -e -o - "$SCRIPT_DIR/specification/E-ARK-CITS-3DHM.adoc" >> "$SCRIPT_DIR/site/index.html"

echo " - Generating specification PDF with asciidoctor."
asciidoctor-pdf -o site/pdf/E-ARK-CITS-3DHM.pdf specification/E-ARK-CITS-3DHM.adoc

echo " - Copying spec-publisher collateral to guidelines directory."
cp -rf "$SCRIPT_DIR/spec-publisher/res/md/common-intro.adoc" "$SCRIPT_DIR/spec-publisher/res/md/figs" "$SCRIPT_DIR/guideline/"

echo " - spec-publisher: generating guidelines, appendices, etc."
# mvn package -f spec-publisher/pom.xml 
java -jar "$SCRIPT_DIR/spec-publisher/target/mets-profile-processor-0.2.0-SNAPSHOT.jar" \
     -f "$SCRIPT_DIR/guideline.yaml" \
     -o "$SCRIPT_DIR/guideline"

echo " - Generating guidelines HTML with asciidoctor."
asciidoctor -a linkcss -a copycss -e -o - "$SCRIPT_DIR/guideline/E-ARK-guideline-3DHM.adoc" >> "$SCRIPT_DIR/site/guidelines/index.html"

echo " - Generating guidelines PDF with asciidoctor."
asciidoctor-pdf -o site/pdf/CITS-3DHM-GUIDELINES.pdf guideline/E-ARK-guideline-3DHM.adoc

echo " - Jekykll converting site for GitHub pages in _site directory."
docker run --rm -v "$PWD"/site:/usr/src/app -v "$PWD"/_site:/_site starefossen/github-pages jekyll build -d /_site

echo " - Cleaning up specification and site directories."
git clean -f "$SCRIPT_DIR/specification/"
git clean -f "$SCRIPT_DIR/site/"
