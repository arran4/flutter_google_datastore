# flutter_google_datastore

![logo.png](assets/logo.png)

A flutter project to browse a google datastore, namely the datastore emulator which seemed to lack
a client however supports connecting to a cloud instance.

![ksnip_20230926-200953.png](images/ksnip_20230926-200953.png)

![ksnip_20230926-201014.png](images/ksnip_20230926-201014.png)

![ksnip_20230926-201027.png](images/ksnip_20230926-201027.png)

![ksnip_20230926-201036.png](images/ksnip_20230926-201036.png)

![ksnip_20230926-210718.png](images/ksnip_20230926-210718.png)

(UI is in need of some adjustments but it works for me right now)

![ksnip_20231114-142327.png](images%2Fksnip_20231114-142327.png)

![ksnip_20231114-142358.png](images%2Fksnip_20231114-142358.png)

![ksnip_20231114-142408.png](images%2Fksnip_20231114-142408.png)

![ksnip_20231114-142542.png](images%2Fksnip_20231114-142542.png)

![ksnip_20231114-142553.png](images%2Fksnip_20231114-142553.png)

![ksnip_20231114-152238.png](images%2Fksnip_20231114-152238.png)

![ksnip_20230926-220928.png](images/ksnip_20230926-220928.png)

See releases, should work on Linux, Mac, Windows, Android and iOS.

## Building
This project uses [FastForge](https://pub.dev/packages/fastforge) (formerly
Flutter Distributor) to package releases. The workflow in
`.github/workflows/release.yaml` runs FastForge automatically. For local
builds you can install the tool with `dart pub global activate fastforge` and
invoke `fastforge release` for the desired target.

# Roadmap
* More authentication methods including android compatible Oauth2
* Ability to create an entity
* Export and import of multiple types both datastore / could and it's own

This project was born out of a personal need, and I welcome sponsorship to help enhance and maintain it for a wider audience.
