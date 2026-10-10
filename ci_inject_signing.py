p = 'android/app/build.gradle'
s = open(p).read()
block = '''signingConfigs {
        release {
            storeFile file("/tmp/dhfa-release.jks")
            storePassword System.getenv("KEYSTORE_PASS")
            keyAlias System.getenv("KEY_ALIAS")
            keyPassword System.getenv("KEY_PASS")
        }
    }
    buildTypes {'''
assert 'buildTypes {' in s, 'buildTypes missing'
s = s.replace('buildTypes {', block, 1)
s = s.replace('signingConfig signingConfigs.debug', 'signingConfig signingConfigs.release')
open(p, 'w').write(s)
print('gradle signing injected OK')
