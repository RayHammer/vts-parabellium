# Parabellium

Parabellium is a plugin originally created to allow modifying custom parameters in VTube Studio, like colors, with ease, while focusing on performance and modularity. If needed, additional parameters can be created and supplied.

## Features

- Token persistence: An auth token is saved to configuration file to allow easy access to the API without having to authorize the plugin if the session is valid
- Custom configuration persistence: Parameters like colors allow swatches to be saved in memory and are written to the configuration file on program shutdown, allowing the new sessions to read this data and load all saved swatches back into the plugin
- Performance: User can control the maximum amount of requests per second (RPS) made by the plugin in order to improve stability and reduce lag while the plugin is active. Parameters that change their values faster than the set value are polled and batched at regular intervals.

## Build

This project is written in [Godot 4](https://godotengine.org/) and is using GDScript for its functionality. To build the project, proceed with the following steps:

- Install Godot 4.x from the [official website](https://godotengine.org/download/)
- Clone the repository and open it in Godot
- Follow [this section](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html) of the official documentation n order to export the project

Currently the project comes with export presets for Windows and Linux. You may require to download export templates for your version of Godot, with the instructions available [here](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html#export-templates)
