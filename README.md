# podverse-ios
Podcast subscribing and clip sharing mobile app.

## Setup

### CocoaPods

Dependencies are loaded using CocoaPods. After cloning the repo, you'll need to install dependencies by typing:

`pod install`

After install finishes, open the Podverse.xcworkspace in Xcode.

### Auth0

Podverse uses Auth0 for user authentication. In order to run the app locally, you will need to sign up for an Auth0 account, then add to the Supporting Files directory a file named Auth0.plist, and add the following key/value pairs:

```
ClientId: {YOUR_CLIENT_ID}
Domain: {YOUR_DOMAIN}
```

You should now be able to run the app, and login with your Auth0 app credentials.

### Server Data

By default, clip and podcast search data is provided by podverse.fm. To change the source of this data, update the corresponding URL/s in the Constants.swift file:

```
let LOCAL_DEV_URL = "http://localhost:8080/"
let DEV_URL = ""
let PROD_URL = ""
let BASE_URL = PROD_URL
```