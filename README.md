# Flutter AWS IoT

AWS IoT plugin for flutter, intended to fit nicely with [flutter_cognito_plugin](https://github.com/scientifichackers/flutter_cognito_plugin) and [mqtt_client](https://pub.dev/packages/mqtt_client).

- Basic pub/sub functionality.
- Supports [AttachPolicy](https://docs.aws.amazon.com/iot/latest/apireference/API_AttachPolicy.html), which is needed to make cognito identity auth work with aws iot.
- Automatically handles cognito identity auth in the background. 

# Install

- Use flutter plugin install instructions on Dart Pub.  
- Ensure `platform :ios, '9.0'` at `ios/Podfile`.
- Add `awsconfiguration.json` by following instructions at [flutter_cognito_plugin](https://github.com/scientifichackers/flutter_cognito_plugin) for Android/iOS.

## Example app

- Clone 

```
git clone https://github.com/IoTReady/flutter-aws-iot.git
cd example
cp assets/.env.example assets/.env
```

- Edit `example/assets/.env` file, and fill in the proper credentials.

- Add `awsconfiguration.json` to the `example` app, by following instructions at [flutter_cognito_plugin](https://github.com/scientifichackers/flutter_cognito_plugin) for both Android/iOS.

- Run

```
flutter run
```

## Prior art 

- [aws_iot_device](https://pub.dev/packages/aws_iot_device)

