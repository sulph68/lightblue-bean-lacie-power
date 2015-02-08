# lightblue-bean-lacie-power
Use a Lightblue Bean to cold power control the Seagate Wireless drive over Bluetooth

iOS App
-------
This is a simple app that uses a lightblue Bean to power control a Seagate wireless drive's power button. It works together with the arduino code to be able to send a short, long press and a blink command to test the responsiveness of the Bean.

The "beanName" variable in both the iOS and Arduino code should be changed to something relatively unique so as to prevent connecting to the wrong Bean.

Arduino Code
------------
Upload the arduino code into the Bean using Lightblue Bean's BeanLoader application and wire the correct pins appropriately. The arduino chip is set to go into sleep as often as possible as long as there is no connecting device. If there is a connecting device, it would check for commands once every 3 seconds.

There are no security and pairing considerations in the code! Anyone can connect to your Bean control as long as they know the bean name!
