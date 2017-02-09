#!/bin/sh

unset TOOLCHAINS

TMP_BUILD_DIR="${PROJECT_DIR}/../tmp_build"
DEST_BUILD_DIR="${PROJECT_DIR}/../SDFBuild/SmartViewSDK-iOS"
BUNDLE_NAME="${PRODUCT_NAME}.${WRAPPER_EXTENSION}"

if [ -d "${DEST_BUILD_DIR}" ]; then
    rm -Rf "${DEST_BUILD_DIR}"
fi

if [ -d "${TMP_BUILD_DIR}" ]; then
rm -Rf "${TMP_BUILD_DIR}"
fi

# Build framework for every platform and architecture
PLATFORM="iphoneos"

CURRENT_ARCH="armv7 armv7s arm64"
xcodebuild  OTHER_CFLAGS="-fembed-bitcode" ENABLE_BITCODE=YES BITCODE_GENERATION_MODE=bitcode \
            -project "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj" \
            -sdk "${PLATFORM}" ARCHS="${CURRENT_ARCH}" -configuration ${CONFIGURATION} clean build \
            SYMROOT="${TMP_BUILD_DIR}/${PLATFORM}" CONFIGURATION_BUILD_DIR="${TMP_BUILD_DIR}/${PLATFORM}/${IPHONE_DEVICE_BUILD_DIR}"

PLATFORM="iphonesimulator"

CURRENT_ARCH="i386 x86_64"
xcodebuild 	OTHER_CFLAGS="-fembed-bitcode" ENABLE_BITCODE=YES BITCODE_GENERATION_MODE=bitcode \
            -project "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj" \
            -sdk "${PLATFORM}" ARCHS="${CURRENT_ARCH}" -configuration ${CONFIGURATION} clean build \
            SYMROOT="${TMP_BUILD_DIR}/${PLATFORM}" CONFIGURATION_BUILD_DIR="${TMP_BUILD_DIR}/${PLATFORM}/${IPHONE_SIMULATOR_BUILD_DIR}"

# Merge armv7 and arm64 frameworks to create iphoneos bundle
PLATFORM="iphoneos"
mkdir -p "${DEST_BUILD_DIR}/${PLATFORM}"
cp -RL "${TMP_BUILD_DIR}/${PLATFORM}/${IPHONE_DEVICE_BUILD_DIR}/${BUNDLE_NAME}" "${DEST_BUILD_DIR}/${PLATFORM}"

#cp  "${TMP_BUILD_DIR}/${PLATFORM}/${IPHONE_DEVICE_BUILD_DIR}/${BUNDLE_NAME}/Modules/${PRODUCT_MODULE_NAME}.swiftmodule/arm.swiftdoc" \
#    "${DEST_BUILD_DIR}/${PLATFORM}/${BUNDLE_NAME}/Modules/${PRODUCT_MODULE_NAME}.swiftmodule"
#cp  "${TMP_BUILD_DIR}/${PLATFORM}/${IPHONE_DEVICE_BUILD_DIR}/${BUNDLE_NAME}/Modules/${PRODUCT_MODULE_NAME}.swiftmodule/arm.swiftmodule" \
#    "${DEST_BUILD_DIR}/${PLATFORM}/${BUNDLE_NAME}/Modules/${PRODUCT_MODULE_NAME}.swiftmodule"

# Merge iphoneos and iphonesimulator frameworks
PLATFORM="iphonesimulator"
mkdir -p "${DEST_BUILD_DIR}/${PLATFORM}"
cp -R "${DEST_BUILD_DIR}/iphoneos/" "${DEST_BUILD_DIR}/${PLATFORM}"

lipo    "${DEST_BUILD_DIR}/${PLATFORM}/${BUNDLE_NAME}/${PRODUCT_NAME}" \
        "${TMP_BUILD_DIR}/${PLATFORM}/${IPHONE_SIMULATOR_BUILD_DIR}/${BUNDLE_NAME}/${PRODUCT_NAME}" \
        -create -output "${DEST_BUILD_DIR}/${PLATFORM}/${BUNDLE_NAME}/${PRODUCT_NAME}"

lipo -remove armv7s "${DEST_BUILD_DIR}/${PLATFORM}/${BUNDLE_NAME}/${PRODUCT_NAME}" -output "${DEST_BUILD_DIR}/${PLATFORM}/${BUNDLE_NAME}/${PRODUCT_NAME}"

cp  "${TMP_BUILD_DIR}/${PLATFORM}/${IPHONE_SIMULATOR_BUILD_DIR}/${BUNDLE_NAME}/Modules/${PRODUCT_MODULE_NAME}.swiftmodule/i386.swiftdoc" \
    "${DEST_BUILD_DIR}/${PLATFORM}/${BUNDLE_NAME}/Modules/${PRODUCT_MODULE_NAME}.swiftmodule"
cp  "${TMP_BUILD_DIR}/${PLATFORM}/${IPHONE_SIMULATOR_BUILD_DIR}/${BUNDLE_NAME}/Modules/${PRODUCT_MODULE_NAME}.swiftmodule/i386.swiftmodule" \
    "${DEST_BUILD_DIR}/${PLATFORM}/${BUNDLE_NAME}/Modules/${PRODUCT_MODULE_NAME}.swiftmodule"

cp  "${TMP_BUILD_DIR}/${PLATFORM}/${IPHONE_SIMULATOR_BUILD_DIR}/${BUNDLE_NAME}/Modules/${PRODUCT_MODULE_NAME}.swiftmodule/x86_64.swiftdoc" \
    "${DEST_BUILD_DIR}/${PLATFORM}/${BUNDLE_NAME}/Modules/${PRODUCT_MODULE_NAME}.swiftmodule"
cp  "${TMP_BUILD_DIR}/${PLATFORM}/${IPHONE_SIMULATOR_BUILD_DIR}/${BUNDLE_NAME}/Modules/${PRODUCT_MODULE_NAME}.swiftmodule/x86_64.swiftmodule" \
    "${DEST_BUILD_DIR}/${PLATFORM}/${BUNDLE_NAME}/Modules/${PRODUCT_MODULE_NAME}.swiftmodule"

mv "${DEST_BUILD_DIR}/iphonesimulator" "${DEST_BUILD_DIR}/iphoneos+iphonesimulator"

rm -Rf "${TMP_BUILD_DIR}"
