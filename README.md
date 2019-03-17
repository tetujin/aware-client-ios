## Deprecated
aware-client-ios has recently been deprecated. Instead of aware-client-ios, a new client named aware-client-ios-v2 is ready on [GitHub](https://github.com/tetujin/aware-client-ios-v2) and [AppStore](https://itunes.apple.com/jp/app/aware-client-v2/id1455986181). Please use the new one if you need to use the client. The sensing module on the new client is built on [AWAREFramework-iOS](https://github.com/tetujin/AWAREFramework-iOS) which is a library version of AWARE framework for iOS. In addition, all source code of the client is written in Swift, so then if you are not familiar with Objective-C, you can easily modify and extend the source code. 

## AWARE Framework Client source code for iOS (http://awareframework.com)
AWARE is an Android and iOS framework dedicated to instrument, infer, log and share mobile context information, 
for application developers, researchers and smartphone users. AWARE captures hardware-, software-, and human-based data. 
The data is then analyzed using AWARE plugins. They transform data into information you can understand.

### Individuals: Record your own data
No programming skills are required. The mobile application allows you to enable or disable sensors and plugins. The data is saved locally on your mobile phone. Privacy is enforced by design, so AWARE does not log personal information, such as phone numbers or contacts information. You can additionally install plugins that will further enhance the capabilities of your device, straight from the client.

### Scientists: Run studies
Running a mobile related study has never been easier. Install AWARE on the participants phone, select the data you want to collect and that is it. If you use the AWARE dashboard, you can request your participants’ data, check their participation and remotely trigger mobile ESM (Experience Sampling Method) questionnaires, anytime and anywhere from the convenience of your Internet browser. The framework does not record the data you need? Check our tutorials to learn how to create your own plugins, or just contact us to help you with your study! Our research group is always willing to collaborate.

### Developers: Make your apps smarter
Nothing is more stressful than to interrupt a mobile phone user at the most unfortunate moments. AWARE provides application developers with user’s context using AWARE’s API. AWARE is available as an Android library. User’s current context is shared at the operating system level, thus empowering richer context-aware applications for the end-users.


## Author
AWARE Framework client for iOS is developed by [Yuuki Nishiyama](https://www.ht.sfc.keio.ac.jp/~tetujin/) (Tokuda Laboratory, SFC, Keio University). Also, [AWARE framework](http://www.awareframework.com/) and [AWARE Framework client](https://github.com/denzilferreira/aware-client) (for Android) were created by [Denzil Ferreira](http://www.denzilferreira.com/) (Community Imaging Group, University of Oulu) and his group originally.

## Contributions
Help is welcome! If you do not know what to do, just pick one item and send me a pull request.
- [x] Develop the library (Cocoapods) version of [AWAREFramework-iOS](https://github.com/tetujin/AWAREFramework-iOS) (2018/4/2)
- [x] Support Swift (The library version supports Swift) (2018/4/2)
- [ ] Wirte test cases 
- [ ] Plugin Update: Keyboard
- [ ] Plugin Update: Event-based ESM (for iOS ESM)
- [x] Plugin Update: Multiple-ESM Interface (for iOS ESM)

## Libraries
AWARE Framework Client for iOS uses following external libraries via [CocoaPod](https://cocoapods.org/).
- [MQTTKit](https://github.com/jmesnil/MQTTKit)
- [SCNetworkReachability](https://github.com/belkevich/reachability-ios)
- [Google/SignIn](https://developers.google.com/identity/sign-in/ios/)
- [ios-ntp](https://github.com/jbenet/ios-ntp)

## License
Copyright (c) 2015 AWARE Mobile Context Instrumentation Middleware/Framework for iOS (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
