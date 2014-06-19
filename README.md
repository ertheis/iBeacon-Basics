##iBeacon Basics: Sending Ads Over iBeacon
==============


Unlike most i-Products, iBeacon is not a physical device. Rather, it is a bluetooth protocol. It allows a device to transmit a small amount of information to another device when they are in close proximity (20m max) of each other. A good way to look at an iBeacon is as a lighthouse. An Observer first needs to know what direction to look in. Once an observer can see the light, he/she can determine color of the light and the frequency with which it rotates. They can also roughly determine how near/far they are from the source. However, with both iBeacons and lighthouses, the source and observer cannot communicate furhter without an external technology. In the case of the lighthouse, a great candidate is a radio. In the case of iBeacons, a great cadidate is PubNub.

In the next two tutorials, I will demonstrate how to use an iDevice as both an iBeacon emitter and an iBeacon observer utilizing the programming language Swift. For these examples, we will pretend that the emitter device is being used by a shopkeeper to send daily deals to observer devices running the store's app. 

We begin with the emitter.

##Coding the Emitter
In this example, 
