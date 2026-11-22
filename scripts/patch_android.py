#!/usr/bin/env python3
"""Patch generated Flutter Android project for DEEN's permissions, notifications,
Firebase Google Services plugin and optional upload-keystore signing.
Run from the mobile/ directory after flutter create.
"""
import os
import re
import sys

ANDROID = os.path.join(os.getcwd(), "android")
manifest_path = os.path.join(ANDROID, "app/src/main/AndroidManifest.xml")
if not os.path.exists(manifest_path):
    sys.exit("Android manifest not found; run flutter create --platforms=android first.")

manifest = open(manifest_path, encoding="utf-8").read()
permissions = [
    "android.permission.INTERNET",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.VIBRATE",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.SCHEDULE_EXACT_ALARM",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.ACCESS_FINE_LOCATION",
]
permission_xml = "".join(
    f'    <uses-permission android:name="{item}"/>\n'
    for item in permissions
    if f'android:name="{item}"' not in manifest
)
manifest = manifest.replace("<application", permission_xml + "    <application", 1)
manifest = re.sub(r'android:label="[^"]*"', 'android:label="DEEN"', manifest, count=1)

# Use a supported Android Gradle Plugin / Gradle pair. Flutter's generated
# wrapper can otherwise inherit the legacy AGP 7.3.0 template, which fails on
# modern SDK/dependency resolution in CI.
settings_path = os.path.join(ANDROID, "settings.gradle")
if os.path.exists(settings_path):
    settings = open(settings_path, encoding="utf-8").read()
    settings = re.sub(
        r'(id\\s+["\']com\\.android\\.application["\']\\s+version\\s+["\'])[^"\']+',
        r'\\g<1>8.6.1',
        settings,
    )
    settings = re.sub(
        r'(id\\s+["\']org\\.jetbrains\\.kotlin\\.android["\']\\s+version\\s+["\'])[^"\']+',
        r'\\g<1>2.0.20',
        settings,
    )
    open(settings_path, "w", encoding="utf-8").write(settings)

root_gradle_path = os.path.join(ANDROID, "build.gradle")
if os.path.exists(root_gradle_path):
    root_gradle = open(root_gradle_path, encoding="utf-8").read()
    root_gradle = re.sub(
        r"(com\\.android\\.tools\\.build:gradle:)[0-9.]+",
        r"\\g<1>8.6.1",
        root_gradle,
    )
    root_gradle = re.sub(
        r"(ext\\.kotlin_version\\s*=\\s*['\"])[^'\"]+",
        r"\\g<1>2.0.20",
        root_gradle,
    )
    root_gradle = re.sub(
        r"(org\\.jetbrains\\.kotlin:kotlin-gradle-plugin:)[0-9.]+",
        r"\\g<1>2.0.20",
        root_gradle,
    )
    open(root_gradle_path, "w", encoding="utf-8").write(root_gradle)

wrapper_path = os.path.join(ANDROID, "gradle/wrapper/gradle-wrapper.properties")
if os.path.exists(wrapper_path):
    wrapper = open(wrapper_path, encoding="utf-8").read()
    wrapper = re.sub(
        r"(distributionUrl=.*gradle-)[0-9.]+(-all\\.zip)",
        r"\\g<1>8.7\\g<2>",
        wrapper,
    )
    open(wrapper_path, "w", encoding="utf-8").write(wrapper)

receivers = """
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""
if "ScheduledNotificationReceiver" not in manifest:
    manifest = manifest.replace("</application>", receivers + "    </application>", 1)
open(manifest_path, "w", encoding="utf-8").write(manifest)

gradle_path = os.path.join(ANDROID, "app/build.gradle")
if not os.path.exists(gradle_path):
    sys.exit("android/app/build.gradle not found; adjust the script for the generated Gradle DSL.")

gradle = open(gradle_path, encoding="utf-8").read()
gradle = re.sub(r"minSdk\s*=?\s*flutter\.minSdkVersion", "minSdk = 23", gradle)
gradle = re.sub(r"compileSdk\s*=?\s*flutter\.compileSdkVersion", "compileSdk = 35", gradle)

if "coreLibraryDesugaringEnabled" not in gradle:
    if "compileOptions {" not in gradle:
        sys.exit("compileOptions block not found in generated Gradle file.")
    gradle = re.sub(
        r"compileOptions\s*\{",
        "compileOptions {\n        coreLibraryDesugaringEnabled true",
        gradle,
        count=1,
    )
    gradle += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"

if os.path.exists(os.path.join(ANDROID, "app/google-services.json")) and "com.google.gms.google-services" not in gradle:
    gradle = re.sub(
        r"plugins\s*\{",
        'plugins {\n    id "com.google.gms.google-services"',
        gradle,
        count=1,
    )
    settings_path = os.path.join(ANDROID, "settings.gradle")
    settings = open(settings_path, encoding="utf-8").read()
    settings = re.sub(
        r"plugins\s*\{",
        'plugins {\n    id "com.google.gms.google-services" version "4.4.2" apply false',
        settings,
        count=1,
    )
    open(settings_path, "w", encoding="utf-8").write(settings)

key_properties = os.path.join(ANDROID, "key.properties")
if os.path.exists(key_properties) and "signingConfigs.release" not in gradle:
    signing_block = """
    signingConfigs {
        release {
            def keystoreProperties = new Properties()
            def keystorePropertiesFile = rootProject.file("key.properties")
            keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
            keyAlias = keystoreProperties["keyAlias"]
            keyPassword = keystoreProperties["keyPassword"]
            storeFile = file(keystoreProperties["storeFile"])
            storePassword = keystoreProperties["storePassword"]
        }
    }
"""
    if not re.search(r"\n\s*buildTypes\s*\{", gradle):
        sys.exit("buildTypes block not found in generated Gradle file.")
    gradle = re.sub(
        r"\n\s*buildTypes\s*\{",
        "\n" + signing_block + "\n    buildTypes {",
        gradle,
        count=1,
    )
    if "signingConfig = signingConfigs.debug" in gradle:
        gradle = gradle.replace(
            "signingConfig = signingConfigs.debug",
            "signingConfig = signingConfigs.release",
            1,
        )
    elif "signingConfig signingConfigs.debug" in gradle:
        gradle = gradle.replace(
            "signingConfig signingConfigs.debug",
            "signingConfig signingConfigs.release",
            1,
        )
    else:
        if "release {" not in gradle:
            sys.exit("Release buildType not found; inspect generated android/app/build.gradle.")
        gradle = re.sub(
            r"(buildTypes\s*\{\s*release\s*\{)",
            r"\1\n            signingConfig = signingConfigs.release",
            gradle,
            count=1,
        )

open(gradle_path, "w", encoding="utf-8").write(gradle)
print("Android configuration patched.")
