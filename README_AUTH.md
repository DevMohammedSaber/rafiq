# Authentication Setup

## Firebase Setup
1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Enable **Authentication**.
3.  Enable **Google** Sign-In provider.
4.  Enable **Apple** Sign-In provider (if targeting iOS).
5.  Enable **Anonymous** (optional, if you want "Guest" to map to anonymous, but current implementation uses local state).

## Android Setup
1.  Add your SHA-1 and SHA-256 fingerprints to the Firebase Android app settings.
    ```bash
    ./gradlew signingReport
    ```
2.  Download `google-services.json` and place it in `android/app/`.

## iOS Setup
1.  Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
2.  Open `ios/Runner.xcworkspace` in Xcode.
3.  Add the **Sign In with Apple** capability in "Signing & Capabilities".
4.  Add custom URL schemes for Google Sign-In in `Info.plist`:
    ```xml
    <key>CFBundleURLTypes</key>
    <array>
    	<dict>
    		<key>CFBundleTypeRole</key>
    		<string>Editor</string>
    		<key>CFBundleURLSchemes</key>
    		<array>
    			<!-- Copied from GoogleService-Info.plist key REVERSED_CLIENT_ID -->
    			<string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
    		</array>
    	</dict>
    </array>
    ```

## Guest Mode
- The app uses `SharedPreferences` to track "Guest" mode locally (`is_guest`).
- Guest users are not authenticated with Firebase by default in this implementation.
