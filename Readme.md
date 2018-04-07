# Intercom - Google Analytics Conversion

- This is a proof of concept of how to track events / conversions in Google Analytics when a person messages into Intercom

## Screenshots

### Creating the Goal in Google Analytics
![Creating a Goal in Google Analytics](/screenshots/Creating%20a%20Goal%20in%20Google%20Analytics.png)

### Starting a conversation in Intercom
![Start Conversation](/screenshots/Start%20Conversation.png)

### Event Triggered in Google Analytics
![Event Triggered](/screenshots/Event%20Triggered.png)

### Goal Hit triggering Conversion
![Goal Hit](/screenshots/Goal%20Hit.png)


## How it works    
- Gets the a Google Analytics Unique Identifier and saves it as a [custom user attribute](https://docs.intercom.io/configuring-intercom/send-custom-user-attributes-to-intercom) on the current session
- Listens for new conversations or replies using [webhooks](https://docs.intercom.io/integrations/webhooks)
- Via webhook processing code uses the [API](https://developers.intercom.io/reference) to read the Google Analytics Unique Identifier for the record</li>
- Use the Google Analytics Server Side code (the [Measurement Protocol](https://developers.google.com/analytics/devguides/collection/protocol/v1/)) to track event/conversion on the current session

## Setup - Environment Variable Configuration
- lists all variables needed for this script to work
- `TOKEN`
	- Apply for an access token  https://app.intercom.io/developers/_
	- A standard access token should be all that is needed as we are just reading user information via Intercom ID which does not require an extended scope
	- Read more about access tokens https://developers.intercom.com/reference#personal-access-tokens-1 
- `APP_ID`
	- your Intercom app_id that you use in the [Javascript Visitor/Logged out Install](https://docs.intercom.com/install-on-your-product-or-site/quick-install/install-intercom-on-your-website-for-logged-out-visitors) / [Javascript user install](https://docs.intercom.io/install-on-your-product-or-site/install-intercom-on-your-web-app)
- `GA_TRACKING_ID`
	- Your Google Analytics Track ID (e.g.UA-ABCDEFGHIJ-K)
- `CUSTOM_ATTRIBUTE_NAME`
	- the name of the custom attribute in Intercom to track the customers Google Analytics Unique identifier (e.g. google_analytics_id)

- For development just rename `.env.sample` to `.env` and modify values appropriately

## Running this locally

```
gem install bundler # install bundler
bundle install      # install dependencies
ruby app.rb         # run the code
ngrok http 4567     # uses https://ngrok.com/ to give you a public URL to your local code to process the webhooks
```

- Create a new webhook in the [Intercom Developer Hub](https://app.intercom.io/developers/_) > Webhooks page
- Listen on the following notification: "New converstions from user or lead" (`conversation.user.created`) and "Reply from a user or lead" / `conversation.user.replied`
- In webhook URL specify the ngrok URL
- Load http://localhost:4567 in the browser and start a conversation
