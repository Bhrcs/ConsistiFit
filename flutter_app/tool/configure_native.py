from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def configure_android() -> None:
    manifest = ROOT / 'android/app/src/main/AndroidManifest.xml'
    if not manifest.exists():
        return
    text = manifest.read_text(encoding='utf-8')
    permissions = '''
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
    <uses-permission android:name="android.permission.health.READ_STEPS" />
    <uses-permission android:name="android.permission.health.READ_ACTIVE_CALORIES_BURNED" />
    <uses-permission android:name="android.permission.health.READ_HEART_RATE" />
    <uses-permission android:name="android.permission.health.READ_EXERCISE" />
    <uses-permission android:name="android.permission.health.READ_SLEEP" />
    <queries>
        <package android:name="com.google.android.apps.healthdata" />
    </queries>
'''
    if 'android.permission.health.READ_STEPS' not in text:
        text = text.replace(
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android">' + permissions,
            1,
        )
    alias = '''
        <activity-alias
            android:name="ViewPermissionUsageActivity"
            android:exported="true"
            android:targetActivity=".MainActivity"
            android:permission="android.permission.START_VIEW_PERMISSION_USAGE">
            <intent-filter>
                <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />
                <category android:name="android.intent.category.HEALTH_PERMISSIONS" />
            </intent-filter>
        </activity-alias>
'''
    if 'ViewPermissionUsageActivity' not in text:
        text = text.replace('</application>', alias + '    </application>', 1)
    manifest.write_text(text, encoding='utf-8')

    gradle = ROOT / 'android/app/build.gradle.kts'
    if gradle.exists():
        gradle_text = gradle.read_text(encoding='utf-8')
        gradle_text = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 26', gradle_text)
        if 'multiDexEnabled = true' not in gradle_text:
            gradle_text = gradle_text.replace('defaultConfig {', 'defaultConfig {\n        multiDexEnabled = true', 1)
        if 'isCoreLibraryDesugaringEnabled = true' not in gradle_text:
            gradle_text = gradle_text.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', 1)
        if 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")' not in gradle_text:
            if 'dependencies {' in gradle_text:
                gradle_text = gradle_text.replace('dependencies {', 'dependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")', 1)
            else:
                gradle_text += '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
        gradle.write_text(gradle_text, encoding='utf-8')


def configure_ios() -> None:
    info = ROOT / 'ios/Runner/Info.plist'
    if info.exists():
        text = info.read_text(encoding='utf-8')
        extra = '''
	<key>NSHealthShareUsageDescription</key>
	<string>ConsistiFit reads activity and workout data you choose to share to show consistency insights.</string>
	<key>NSHealthUpdateUsageDescription</key>
	<string>ConsistiFit may save workouts you choose to share with Apple Health.</string>
'''
        if 'NSHealthShareUsageDescription' not in text:
            text = text.replace('</dict>', extra + '</dict>', 1)
        info.write_text(text, encoding='utf-8')

    entitlements = ROOT / 'ios/Runner/Runner.entitlements'
    entitlements.parent.mkdir(parents=True, exist_ok=True)
    entitlements.write_text('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.healthkit</key>
	<true/>
</dict>
</plist>
''', encoding='utf-8')

    project = ROOT / 'ios/Runner.xcodeproj/project.pbxproj'
    if project.exists():
        text = project.read_text(encoding='utf-8')
        text = re.sub(r'IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;', 'IPHONEOS_DEPLOYMENT_TARGET = 15.0;', text)
        if 'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;' not in text:
            text = text.replace(
                'PRODUCT_BUNDLE_IDENTIFIER = com.consistifit.consistifit;',
                'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\n\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.consistifit.consistifit;',
            )
        project.write_text(text, encoding='utf-8')


def main() -> None:
    configure_android()
    configure_ios()
    print('ConsistiFit native Health and notification configuration applied.')


if __name__ == '__main__':
    main()
