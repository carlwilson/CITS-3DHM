#!/usr/bin/env bash
echo "Generating GitHub pages site from markdown"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR" || exit

echo " - Cleaning up site directory and copying spec-publisher site..."
git clean -f "specification/"
git clean -f "guideline/"
git clean -f "site/"
git checkout "site/index.html"
git checkout "site/guidelines/index.html"

if [ -d _site ]
then
  echo " - Removing old _site directory contents"
  rm -rf "_site/*"
fi

echo " - copying files to site directory..."
# Copy spec-publisher artifacts to the site
cp -rf "spec-publisher/site/"* "spec-publisher/res/md/figs" "site/"
# Copy remaining project collaterel to the site
cp -rf "profile" "examples" "schema" "specification/figs" "pdf" "site/"
cp -rf "guideline/figs" "spec-publisher/res/md/figs" "site/guidelines/"

echo " - spec-publisher: generating specification requirement tables, appendices, etc."
mvn package -f spec-publisher/pom.xml 
java -jar "spec-publisher/target/mets-profile-processor-0.2.0-SNAPSHOT.jar" \
     -f "specification.yaml" \
     -o "specification" \
     "profile/E-ARK-3DHM-ROOT_v1.0.0.xml" "profile/E-ARK-3DHM-REPRESENTATION_v1.0.0.xml"

echo " - Copying spec-publisher collateral to specification directory."
cp -rf "spec-publisher/res/md/common-intro.adoc" "spec-publisher/res/md/figs" "specification/"

echo " - Generating specification HTML with asciidoctor."
asciidoctor -a linkcss -a copycss -e -o - "specification/E-ARK-CITS-3DHM.adoc" >> "site/index.html"

echo " - Generating specification PDF with asciidoctor."
asciidoctor-pdf -o site/pdf/E-ARK-CITS-3DHM.pdf specification/E-ARK-CITS-3DHM.adoc

echo " - Copying spec-publisher collateral to guidelines directory."
cp -rf "spec-publisher/res/md/common-intro.adoc" "spec-publisher/res/md/figs" "guideline/"

echo " - spec-publisher: generating guidelines, appendices, etc."
java -jar "spec-publisher/target/mets-profile-processor-0.2.0-SNAPSHOT.jar" \
     -f "guideline.yaml" \
     -o "guideline" \
     "profile/E-ARK-3DHM-ROOT_v1.0.0.xml"

echo " - Generating guidelines HTML with asciidoctor."
asciidoctor -a linkcss -a copycss -e -o - "guideline/E-ARK-guideline-3DHM.adoc" >> "site/guidelines/index.html"

echo " - Generating guidelines PDF with asciidoctor."
asciidoctor-pdf -o site/pdf/CITS-3DHM-GUIDELINES.pdf guideline/E-ARK-guideline-3DHM.adoc

echo " - Jekykll converting site for GitHub pages in _site directory."
docker run --rm -v "$PWD"/site:/usr/src/app -v "$PWD"/_site:/_site starefossen/github-pages jekyll build -d /_site

echo " - Cleaning up specification and site directories."
git clean -f "specification/"
git clean -f "guideline/"
git clean -f "site/"
