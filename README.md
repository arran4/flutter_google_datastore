# flutter_google_datastore

![logo.png](assets/logo.png)

**Flutter Google Datastore** is a cross platform application for exploring and
editing Google Cloud Datastore.  It started life as a GUI for the Datastore
emulator but it can also connect to a live Cloud project using your `gcloud`
credentials.  The project provides installers for desktop, mobile and web so
you can browse your data from almost anywhere.

## Features

* Connect to the Datastore emulator or a real Cloud Datastore instance.
* Manage multiple projects and authentication profiles.
* Browse namespaces and kinds with paging support.
* View, edit and delete entity properties.
* Download entity properties as JSON or load properties from JSON files.

The screenshots below show the current user interface in action.  Some rough
edges remain but the application is fully functional.

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


## Downloads

Pre-built packages for Linux, macOS, Windows, Android and iOS are available on
the [GitHub releases](https://github.com/arran4/flutter_google_datastore/releases)
page.

## Building
This project uses [FastForge](https://pub.dev/packages/fastforge) (formerly
Flutter Distributor) to package releases. The workflow in
`.github/workflows/release.yaml` runs FastForge automatically. For local
builds you can install the tool with `dart pub global activate fastforge` and
invoke `fastforge release` for the desired target.

## Roadmap
* More authentication methods including android compatible Oauth2
* Ability to create an entity
* Export and import of multiple types both datastore / could and it's own

This project was born out of a personal need, and I welcome sponsorship to help enhance and maintain it for a wider audience.
