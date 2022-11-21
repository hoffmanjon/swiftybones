# swiftybones

This library is based on the libgpiod library as described in our previous post Controlling GPIO pins with libgpiod and Swift. We have mapped the pins for the BeagleBone Black and AI-64. If anyone has another board, like the Raspberry Pi and would like to map the GPIO pins, we would love to support other boards.

Now the question is, how do we use this new library. Lets spend the rest of this post exploring that.   The first thing we need to do is to create a new swift project, we will call this project swiftybonestest.  Use the following commands to create the project

mkdir swiftybonestest
cd swiftybonestest
swift package init --type executable

Now we will want to edit the Package.swift file so the project will download and use the Swiftybones module.  Open up the Package.swift file and add the lines that are highlighted in the following code.
```
// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swiftybonestest",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/hoffmanjon/swiftybones", from: "0.0.9")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "swiftybonestest",
            dependencies: ["swiftybones"]),
        .testTarget(
            name: "swiftybonestestTests",
            dependencies: ["swiftybonestest"]),
    ]
)
```
Note, If you are using Swift 5.7 you can replace your Package.swift file with this one, but if you are using a different version you will want to just update your file with the highlighted lines.  

Now we are ready to use the Swiftybones library.  Edit the Sources/swiftybonestest/swiftybonestest.swift file and add the following code.
```
import swiftybones

@main
public struct swiftybonestest {
    public static func main() async {
        if var gpio = DigitalGPIO(pinId: "P8_04", board: .beagleboneai64, direction: .OUT) {
            for i in 1...8 {
                let active = gpio.isPinActive()
                let current = gpio.getValue()
                print("\(active) - \(i) - \(current!.rawValue)")
                gpio.reversePin()
                try? await Task.sleep(until: .now + .seconds(2), clock: .continuous)
            }
        }      
    }
}
```
In this code we begin by importing the swiftybones module. We make the main() function async so we can use the Task.sleep() function. 

The first line of the main() function initializes pin 4 of the P8 header using the DigitialGPIO(pinId:board:direction) function.  

Within the for loop we check to see if the pin is active using the isPinActive() function and also get the current value of the pin using the getValue() function.  We are retrieving the values of these functions purely for debug purposes and print them to the console.  

We then reverse the value of the pin using the reversePin() function therefore if the pin is high, it will go low or if the pin is low it will go high.  Finally, we pause the application for two seconds before continuing the for loop.

For test purposes I connected a led with a 470 ohm resistor in series to pin 4 of the P8 header.  When the code is run the led will turn off and on every two seconds.  

