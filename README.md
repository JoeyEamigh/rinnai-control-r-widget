# rinnai-control-r-widget

This is an iOS application written in Swift and SwiftUI that was created with one simple purpose: to create a homescreen widget for Rinnai water heaters. The Rinnai Control-R app is difficult to use and isn't very descriptive when it comes to certain events (like trying to stop recirculation during a schedule - spoiler: it doesn't work). It also doesn't have a widget for easy access to the app, and the app's launch time is... subpar (sorry if you are a dev of that app I don't mean to be dissing you :).

Without further ado: presenting rC-r Widget!

Here is the AppStore description:

```md
Features:
- Full replacement for the Rinnai Control-R app's recirculation on and off functions
- Home screen widget to keep you informed on your device's recirculation status
- Passwordless login for easy access

This application was made for fun, and has been very useful personally. The source code is available at https://github.com/JoeyEamigh/rinnai-control-r-widget.
```

In case you are wondering how the app works without a password, it is pretty simple. There is _no authentication on the Rinnai API_.

Shout out to `explosivo22` on GitHub for reverse engineering Rinnai's API and shedding light on the unauthenticated nature of this API! See their work at <https://github.com/explosivo22/rinnaicontrolr>!

Hopefully this can be useful to someone! If not, it sure as hell is nice for me.
