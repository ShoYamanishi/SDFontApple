#!/bin/sh
xcodebuild archive -scheme SDFont -configuration Release -destination 'generic/platform=iOS' -archivePath './build/SDFont.framework-iphoneos.xcarchive' SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
xcodebuild archive -scheme SDFont -configuration Release -destination 'generic/platform=iOS Simulator' -archivePath './build/SDFont.framework-iphonesimulator.xcarchive' SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
xcodebuild archive -scheme SDFont -configuration Release -sdk macosx -archivePath './build/SDFont.framework-macos.xcarchive' SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
xcodebuild -create-xcframework -framework './build/SDFont.framework-iphoneos.xcarchive/Products/Library/Frameworks/SDFont.framework' -framework './build/SDFont.framework-iphonesimulator.xcarchive/Products/Library/Frameworks/SDFont.framework' -framework './build/SDFont.framework-macos.xcarchive/Products/Library/Frameworks/SDFont.framework' -output './build/SDFont.xcframework'
xcodebuild docbuild -scheme SDFont -derivedDataPath ./build
cp -r ./build/Build/Products/Release/SDFont.doccarchive .
xcodebuild archive -scheme sdfontgen -configuration Release -sdk macosx -archivePath './build/sdfontgen' SKIP_INSTALL=NO
cp build/sdfontgen.xcarchive/Products/usr/local/bin/sdfontgen ./build/

while true; do
    read -p "Do you wish to install SDFont.framework--macosx to this Mac under /Library/Frameworks?" yn
    case $yn in
        [Yy]* ) sudo cp -r build/SDFont.xcframework/macos-arm64_x86_64/SDFont.framework /Library/Frameworks; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
