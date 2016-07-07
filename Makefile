all:
	pod install

doc:
	appledoc --project-name "AWARE Client iOS" --project-company "AWARE"  --create-html --create-docset --install-docset --no-create-docse --output ./ ./

appledoc-install:
	brew install homebrew/versions/appledoc22






