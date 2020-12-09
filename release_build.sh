#!/bin/sh
#
# Enterprise Dev
# sh release_build.sh export_options_enterprise.plist iOSHelloWorld.xcworkspace Debug 'Toyota' "iPhone Developer" 2.2 1
# sh release_build.sh export_options_enterprise.plist iOSHelloWorld.xcworkspace Debug Lexus  "iPhone Developer" 2.2 1

# Enterprise Distribution
# sh release_build.sh export_options_enterprise.plist iOSHelloWorld.xcworkspace Release 'iOSHelloWorld' "iPhone Distribution: OPENLANE, Inc" 2.2 1
# sh release_build.sh export_options_enterprise.plist iOSHelloWorld.xcworkspace UAT1 Lexus  "iPhone Distribution: OPENLANE, Inc" 2.2 1
# sh release_build.sh export_options_enterprise.plist iOSHelloWorld.xcworkspace UAT1 Toyota "iPhone Distribution: OPENLANE, Inc" 2.2 1
# sh release_build.sh export_options_enterprise.plist iOSHelloWorld.xcworkspace TEST1 Lexus "iPhone Distribution: OPENLANE, Inc" 2.2 1

# Production
# sh release_build.sh export_options_app_store.plist iOSHelloWorld.xcworkspace Production 'Toyota' "iPhone Distribution: ADESA CORPORATION, LLC (8CB97S5762)" 2.2 1

# sh release_build.sh export_options_enterprise.plist iOSHelloWorld.xcworkspace Debug 'Lexus' "iPhone Developer" 2.2 1
# sh release_build.sh export_options_enterprise.plist iOSHelloWorld.xcworkspace Stage 'Lexus' "iPhone Distribution: OPENLANE, Inc" 2.2 1
# sh release_build.sh export_options_app_store.plist iOSHelloWorld.xcworkspace Production 'Lexus' "iPhone Distribution: ADESA CORPORATION, LLC (8CB97S5762)" 2.2 1

# build for Simulator
# sh release_build.sh simulator Adesa.xcworkspace Debug 'Toyota' "iPhone Developer" 2.2 1
 
 
EXPORT_OPTIONS_PLIST=$1
WORKSPACE_FILE=$2
CONFIGURATION=$3
SCHEME=$4
CODE_SIGN_IDENTITY=$5
APP_VERSION=$6
APP_VERSION_BUILD=$7
BUILD_HISTORY_DIR="output_${APP_VERSION_BUILD}" 
SCHEME_NO_WHITESPACE="$(echo "${SCHEME}" | tr -d '[:space:]')"

IPA_NAME="iOS-${SCHEME_NO_WHITESPACE}-${CONFIGURATION}-${APP_VERSION}-${APP_VERSION_BUILD}"

ECHO EXPORT_OPTIONS_PLIST: ${EXPORT_OPTIONS_PLIST}
ECHO WORKSPACE_FILE: ${WORKSPACE_FILE}
ECHO CONFIGURATION: ${CONFIGURATION}
ECHO SCHEME: ${SCHEME}
ECHO IPA_NAME: ${IPA_NAME}
ECHO CODE_SIGN_IDENTITY: ${CODE_SIGN_IDENTITY}

if [ "${WORKSPACE}" == "" ] 
then
	WORKSPACE=$PWD
fi

echo "hello - ${WORKSPACE}"

# change version number
if [ "${SCHEME}" == "iOSHelloWorld" ] 
then
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString '${APP_VERSION}'" "${WORKSPACE}/iOSHelloWorld/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion '${APP_VERSION_BUILD}'" "${WORKSPACE}/iOSHelloWorld/Info.plist"           
fi


# sh release_build.sh simulator Adesa.xcworkspace Debug 'Toyota' "iPhone Developer" 2.2 1
# xcodebuild -arch i386 -sdk iphonesimulator -workspace "Adesa.xcworkspace" -scheme "Lexus" -configuration "Debug" -derivedDataPath _TestAutomation/AppiumApp/build
if [ $EXPORT_OPTIONS_PLIST == "simulator" ] 
then	
	echo "Building for Simulator"
	xcodebuild -arch i386 -sdk iphonesimulator -workspace ${WORKSPACE_FILE} -scheme "${SCHEME}" -configuration ${CONFIGURATION} -derivedDataPath ./build-sim
else
	# compile project
	echo "Building Project"
	cd "${PROJDIR}"

	mkdir -p "./${BUILD_HISTORY_DIR}"

	rm -rf ~/Library/Developer/Xcode/DerivedData/Adesa-*/

	security unlock-keychain -popenlane ~/Library/Keychains/login.keychain
	xcrun xcodebuild clean archive -quiet -workspace ${WORKSPACE_FILE} -derivedDataPath ${BUILD_HISTORY_DIR}/${SCHEME}-${CONFIGURATION}-derivedData -scheme "${SCHEME}" -configuration ${CONFIGURATION} -archivePath ${BUILD_HISTORY_DIR}/${SCHEME}-${CONFIGURATION}-archive/Adesa.xcarchive CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}"

	xcrun xcodebuild -exportArchive -quiet -exportPath "${BUILD_HISTORY_DIR}/${SCHEME}-${CONFIGURATION}-export" -archivePath ${BUILD_HISTORY_DIR}/${SCHEME}-${CONFIGURATION}-archive/Adesa.xcarchive/ -exportOptionsPlist ${EXPORT_OPTIONS_PLIST} CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" 

	# check if build succeeded
	if [ $? != 0 ]
	then
	  exit 1
	fi
 
	#rm -rf "TDD.ipa"
	#rm -rf "./build"

	# rename the iPA file
	mv "${BUILD_HISTORY_DIR}/${SCHEME}-${CONFIGURATION}-export/${SCHEME}.ipa" "./${BUILD_HISTORY_DIR}/${IPA_NAME}.ipa"

	rm -rf "${BUILD_HISTORY_DIR}/${SCHEME}-${CONFIGURATION}-archive"
	rm -rf "${BUILD_HISTORY_DIR}/${SCHEME}-${CONFIGURATION}-derivedData"
	rm -rf "${BUILD_HISTORY_DIR}/${SCHEME}-${CONFIGURATION}-export"

	# remove all the GIT changes.
	# git checkout -f .

	echo "./${BUILD_HISTORY_DIR}/${IPA_NAME}.ipa ready for upload"
fi
