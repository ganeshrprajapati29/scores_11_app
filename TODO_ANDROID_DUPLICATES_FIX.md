# Android Duplicate Classes Fix TODO

## Steps:
- [x] 1. Edit \`cric11_app/android/gradle.properties\` - Add \`android.enableJetifier=true\`
- [ ] 2. Edit \`cric11_app/android/app/build.gradle\` - Set minSdk 21 + add resolutionStrategy
- [ ] 3. Run cleanup: \`flutter clean\`
- [ ] 4. Run \`cd cric11_app/android && ./gradlew cleanBuildCache && cd ../..\`
- [ ] 5. Run \`flutter pub get\`
- [ ] 6. Test build: \`flutter build apk --debug\`
- [ ] 7. Update TODO_ANDROID_FIX.md with completion note
- [ ] 8. Verify no duplicates on \`./gradlew app:dependencies | grep support\``
