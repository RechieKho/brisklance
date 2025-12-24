# Brisklance

Brisklance is a simple addon manager suite for Godot, inspired from package manager such as [NPM](https://www.npmjs.com).
It is to address the issue of Godot's Asset Store not supporting automatic dependency installation.
It utilize Github's release as host to host archives.

## Setting up

To setup brisklance, you will need to download the `brisklance.zip` from the [release page](https://github.com/RechieKho/brisklance/releases).
Then, extract the files and place it under `res://addons/brisklance` directory as it matches the directories shown in [Directories Description](#directories-descriptions)

However, if you are attempting to create plugins that could be installed via brisklance, it would be wise to utilize this repository as a template.
This is because this template already set up the necessary github workflow to publish your plugin in the format acceptable to brisklance.

## Export addons to Brisklance

To make your addons accessible by Brisklance, the only requirement is to upload a `brisklance_module.zip` file as asset to the release of your Github repository.
This is usually automated with Github workflow. Once you set up the file, brisklance will find the file, download it and extract the content to `res://addons/brisklance/plugins` directory.

## Directories Descriptions

Here discusses the curcial directory and its description to further explain on how brisklance works.

| Directory                         | Description                                                                                                                                                        |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `res://addons/brisklance/manager` | Here lies all the script that manages download and installations.                                                                                                  |
| `res://addons/brisklance/plugins` | Here lies all the downloaded plugins. The installed plugins are excluded from versioning system as it is autoamtically installed during start up and installation. |
| `res://addons/brisklance/self`    | Here lies your own plugin. The installed plugins will be registered to the plugin as dependencies.                                                                 |

## Dependency Resolution

To make dependency resolution simplified, any conflicting dependent plugin should be resolved manually.
Let's assume a scenario in which plugin Foo and plugin Bar both depend on plugin Car.
Then, you must install plugin Car as the main plugins to install both Foo and Bar.
This enforces you, the user, to choose the correct version of the plugin Car that works for both Foo and Bar.
