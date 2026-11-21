#!/usr/bin/env python3
"""Run after `flutter create` to apply DEEN's native Android configuration
(permissions, boot receivers, desugaring, minSdk, optional Firebase plugin)."""
import os, re, sys

M = os.path.join(os.getcwd(), "android")
manifest = os.path.join(M, "app/src/main/AndroidManifest.xml")
m = open(manifest).read()

perms = [
    "android.permission.INTERNET", "android.permission.POST_NOTIFICATIONS", "android.permission.VIBRATE",
    "android.permission.RECEIVE_BOOT_COMPLETED", "android.permission.SCHEDULE_EXACT_ALARM",
    "android.permission.ACCESS_COARSE_LOCATION", "android.permission.ACCESS_FINE_LOCATION",
]
add = "".join(f'    <uses-permission android:name="{p}"/>\n' for p in perms if p not in m)
m = m.replace("<application", add + "    <application", 1)
m = re.sub(r'android:label="[^"]*"', 'android:label="DEEN"', m, count=1)
receivers = '''
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
'''
if "ScheduledNotificationReceiver" not in m:
    m = m.replace("</application>", receivers + "    </application>", 1)
open(manifest, "w").write(m)

# app/build.gradle (groovy) or build.gradle.kts
gradle = os.path.join(M, "app/build.gradle")
if os.path.exists(gradle):
    g = open(gradle).read()
    g = re.sub(r"minSdk\s*=?\s*flutter\.minSdkVersion", "minSdk = 23", g)
    g = re.sub(r"compileSdk\s*=?\s*flutter\.compileSdkVersion", "compileSdk = 35", g)
    if "coreLibraryDesugaringEnabled" not in g:
        g = re.sub(r"compileOptions\s*\{", "compileOptions {\n        coreLibraryDesugaringEnabled true", g, count=1)
        g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    if os.path.exists(os.path.join(M, "app/google-services.json")) and "google-services" not in g:
        g = re.sub(r'plugins\s*\{', 'plugins {\n    id "com.google.gms.google-services"', g, count=1)
        s = os.path.join(M, "settings.gradle")
        t = open(s).read()
        t = re.sub(r'plugins\s*\{', 'plugins {\n    id "com.google.gms.google-services" version "4.4.2" apply false', t, count=1)
        open(s, "w").write(t)
        print("Firebase google-services plugin enabled")
    open(gradle, "w").write(g)
else:
    sys.exit("android/app/build.gradle not found (Kotlin DSL template?). Adjust patch_android.py.")
print("Android configuration patched")
