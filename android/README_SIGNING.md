# Android release signing

To build a release AAB for Google Play, create a keystore and configure signing once.

## 1. Create the keystore (one-time)

Run in a terminal (you’ll be asked for passwords and name):

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- Put `upload-keystore.jks` in the `android/` folder (or somewhere safe and use that path in step 2).
- Remember the passwords and the alias (`upload`).

## 2. Create key.properties

From the `android/` folder:

```bash
cp key.properties.example key.properties
```

Edit `key.properties` and set:

- `storePassword` – password for the keystore
- `keyPassword` – password for the key
- `keyAlias` – e.g. `upload`
- `storeFile` – path to the `.jks` file, e.g. `upload-keystore.jks` if it’s in `android/`, or an absolute path

Do not commit `key.properties` (it’s in `.gitignore`).

## 3. Build release AAB

From the project root:

```bash
flutter build appbundle --release
```

The AAB will be at `build/app/outputs/bundle/release/app-release.aab`.
