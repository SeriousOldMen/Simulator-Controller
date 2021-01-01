# Simulator Controller

Simulator Controller is a modular and extandable adminstration and controller application for complex Sim Racing Rigs. At the core is a comprehensive plugin capable automation framework, which can use almost any external controller hardware, such as Button Boxes, to control typical simulator components such as SimHub, SimFeedback and alike. But there are a lot more functionality and features available to make the life of all of us virtual racers even more fun and simple. You will find a [comprehensive overwiew](https://github.com/SeriousOldMan/Simulator-Controller#main-features) of all features later in this document, but first things first...

### Donation

If you find this tool useful, please help me with the further development. Any donation contributed will be used only to support the project.

[![](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/donate?hosted_button_id=7GV86ZPS95SL6)

Thank you very much for your support!

### Download and Installation

Download one of the builds below and unzip anywhere you like. Then run the configuration tool available in the Binaries folder and configure your environment (you may want to delete all *.ini files the Config folder to start out with a really fresh configuration, but be sure to make a backup copy elsewhere for later reference, especially for the *Simulator Configuration.ini* file. An installation of the underlying programming language [AutoHotkey](https://github.com/SeriousOldMan/Simulator-Controller#third-party-applications) is only necessary, if you want to create your own plugins, but you need a good understanding of the Hotkey syntax to bind your controller hardware to the plugin functions and actions using the configuration tool.
For further convinience, you can place links to **Simulator Startup** and **Simulator Settings** in the Windows Start Menu. You can also configure the software to automatically start with Windows by checking the *Start with Windows* in the first tab of the configuration tool.

See the complete documentation about [Installation & Configuration](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#installation) for more information.

A word about Antivirus warnings: The programming language used for building Simulator Controller uses some really nasty tricks to control Windows applications, tricks also used by malware. Therefore, depending on your concrete Antivirus program, you may get some warnings regarding the Simulator Controller applications. I can assure you, that there's nothing about it. But you can read about these issues in the forums of [AutoHotkey](https://www.autohotkey.com/) itself. If your Antivirus programm allows exception rules, please define rules for the Simulator Controller applications, otherwise you need to have a beer and search for another Simulator Controller tool. Sorry...

Below you will find download links for the current development build and the two latest stable releases. For release information, even for a preview on upcoming features in the next stable build, please take a look at the [release notes](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Release-Notes).

#### Latest development build

None for the moment. Please use one of the release builds below.

#### Latest release builds

[1.3.3-stable](https://www.dropbox.com/s/2yd3s8d591cm27l/Simulator%20Controller%201.3.3-stable.zip?dl=1)

[1.4.4-release](https://www.dropbox.com/s/a5qhbls72zm46xz/Simulator%20Controller%201.4.4-release.zip?dl=1)

### Main features

  - Connect all your external controller, like Button Boxes, to one single center of control
    - An unlimited number of layers of functions and actions, called modes, can be defined for your controller. Switch between modes simply by pushing a button or switch a toggle on your controller. Here is an example of several layers of functions and actions combined in five modes:
	
	![](./Docs/Images/Button%20Box%20Layout.jpg)
	
	- Modes are defined and handled by [plugins](https://github.com/SeriousOldMan/Simulator-Controller#included-plugins), which can be implemented using an objecct oriented scripting language.
  - Configurable, visual feedback for your controller actions
    - Define your own Button Box visual and integrate it with the Simulator Controller using the simple plugin support. Depending on configuration, this window will popup whenever an action is triggered from your controller, even during active simulation
    
    ![](./Docs/Images/Button%20Box%202.JPG)
    
    - Code your own functions to be called by the controller buttons and switches using the simple, object-oriented scripting language
  - Configure all additional [applications](https://github.com/SeriousOldMan/Simulator-Controller#third-party-applications) to your taste, including the simulation games used for your virtual races
    - Start and stop applications from your controller hardware or automatically upon configurable events
    - Add splash screens and title melodies using a themes editor for a more emotional startup experience
    - Full support for sophisticated application automation - for example, start your favorite voice chat software like TeamSpeak and automatically switch to your standard channel 
  - Several plugins are supplied out of the box:
    - Support for Assetto Corsa and Assetto Corsa Competizione already builtin
    - Fully customizable plugins supplied for total control of SimHub and SimFeedback - change your settings while racing using the dials and switches on your favorite Button Box
    - Send your predefined kudos and rants to the ingame chat without touching the keyboard
  - Additional support to trigger every function and action from external sources like a voice or gesture recognition software to always keep your hands on the wheel
  - Builtin support for visual head tracking to control ingame viewing angle - see [third party applications](https://github.com/SeriousOldMan/Simulator-Controller#third-party-applications) below

Simulator Controller is fully implemented in AutoHotkey, a very sophisticated and object-oriented Windows automation scripting language, which is capable to control keyboard and other input devices with a simple macro language. On the other hand, AutoHotkey also has a lot of robotics capabilities to automate software packages, which do not provide external APIs, by simulating mouse clicks and keyboard input. You can write your own plugins using the AutoHotkey language. Full source code for all included plugins with different complexity from simple to advanced is provided to help you get started.

### Additional features

  - Configurable and automated build tool for developers
  - Sophisticated logging, tracing and debug support to track down any errors while developing your own plugins
  - Fully graphical configuration utilities
  
  ![](./Docs/Images/Settings%20Editor.JPG) ![](./Docs/Images/Configuration%20Editor.JPG)

### Included plugins

These plugins are part of the Simulator Controller distribution. Beside providing functionality to the core, they may be used as templates for building your own plugins. They range from very simple functional additions with only a small number of lines of code up to very complex, multi-class behemoths controlling external software such as SimHub.

| Plugin | Description |
| ------ | ------ |
| System | Handles multiple Button Box layers and manages all applications configured for your simulation configuration. |
| Tactile Feedback | Fully configurable support for pedal and chassis vibration using [SimHub](https://github.com/SeriousOldMan/Simulator-Controller#third-party-applications). |
| Motion Feedback | Fully configurable support for rig motion feedback using [SimFeedback](https://github.com/SeriousOldMan/Simulator-Controller#third-party-applications). |
| ACC | Special support for starting and stopping Assetto Corsa Competizione from your hardware controller and supplies functions and actions for configurable, automated chat messages in a multiplayer game. Although quite small with little more than 100 lines of code, this plugin uses configuration based data and defines a simulator dependent mode. Therefore it supplies a good showcase when starting your own plugin development. |
| AC | Special support for starting and stopping Assetto Corsa from your hardware controller. |
| Button Box | Tools for building your own Button Box / controller visuals. An easy to understand example will help you building the screen representation of your own Button Boxes. |

### Third party applications

The following applications are not part of the distribution and are not strictly necessary for Simulator Controller. But Simulator Controller is aware of these components and will integrate them for a better overall experience, if available.

| Application | Description |
| ------ | ------ |
| [AutoHotkey](https://www.autohotkey.com/) | [Development Only] Object oriented scripting language. You need it, if you want to develop your own plugins. |
| [NirCmd](https://www.nirsoft.net/utils/nircmd.html) | [Optional] Extended Windows command shell. Used by Simulator Controller to control ingame sound volume settings during startup. |
| [VoiceMacro](http://www.voicemacro.net/) | [Recommended] Connects to your microphone and translates voice commands to complex keyboard and/or mouse input. These macros can be connected to Simulator Controller as external input to control functions and actions identical to your hardware controller. |
| [AITrack](https://github.com/AIRLegend/aitrack) | [Optional] Neat little tool which uses neural networks to detect your viewing angle on a dashcam video stream. Used in conjunction with opentrack to control your ingame viewing angle. |
| [opentrack](https://sourceforge.net/projects/opentrack.mirror/) | [Recommended] Connects to your simulation game and controls the viewing angle using the freetrack protocol. Several input methods are supported, for example analog joysticks or UDP based sources such as AITrack. |
| [SimHub](https://www.simhubdash.com/) | [Recommended] Versatile, multipurpose software collection for simulation games. Generate vibration using bass shakers or vibration motors using a fully integrated Arduino development environment. Additional features support the definition of custom dashboards. A special plugin is part of Simulator Controller to control the tactile feedback options of SimHub, such as vibration strength, with a touch of a button. |
| [SimFeedback](https://www.opensfx.com/) | [Optional] Not only a software, but a complete DIY project for building motion rigs. SimFeedback controls the motion actuators using visual control curves, which translate the ingame physics data to complex and very fast rig movements. Here also, a plugin is integrated in Simulator Controller to use your hardware controller for controlling SimFeedback. |
| [SFX-100-Streamdeck](https://github.com/ashupp/SFX-100-Streamdeck) | [Optional] This extension for SimFeedback is used to connect to SimFeedback in order to control effect states and intensities. If not used, a subset of the SimFeedback settings will be controlled by mouse automation, which on a side effect requires the SimFeedback window to be the topmost. Since this is not really funny, while currently trying to overtake one of your opponents in a difficult chicane, I strongly advice to install the connector extension, but this requires the *commercial* expert license for SimFeedback. |

### Documentation

A very [extensive documentation](https://github.com/SeriousOldMan/Simulator-Controller/wiki) will guide you through the configuration process and will help you to understand the inner concepts and all the functions & features of Simulator Controller. For developers, who want to create their own plugins, a complete [devlopers guide & reference](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Development-Overview-&-Concepts) is available as well.

The markdown files, the so to say source code of this Wiki can be found in the [Docs](https://github.com/SeriousOldMan/Simulator-Controller/tree/main/Docs) folder.

### Known issues

1. [Fixed] Sometimes, the ingame sound volume is not correctly resetted after playing the startup melody. In those situations, you can use the mixer utility of Windows to bring the volume back up.
2. [Gone] Connection between the "Motion Feedback" plugin and *SimFeedback* has stabilty issues. Looks like the root cause is located in the *SFX-100-Streamdeck* extension.
3. The language drop down in the configuration tool does not adopt to changed languages, after the translation editor has been used.

### Development

For new features coming in the next release, take a look at the [Release Notes](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Release-Notes).

Want to contribute? Great!

  - Build your own plugins and offer them on GitHub. Contact me and I will add a link to your plugin in this documentation.

  - Found a bug, or built a new feature? Even better. Please contact me, and I will give you access to the code repository.

### To Do

Nothing critical for the moment, just relaxing and preparing for the 12h of Bathurst.
  
But the development of Simulator Controller still goes on with one release every week. There are a lot of ideas in the [backlog](https://github.com/SeriousOldMan/Simulator-Controller/wiki/Backlog)...

### License

This software is provided as is. You are free to use it for any purpose and modify it to your needs, as long as you do not use it for any commercial purposes.

(2021) Creative Commons - BY-NC-SA - by Oliver Juwig (TheBigO)
