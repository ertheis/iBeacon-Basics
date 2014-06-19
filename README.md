#iBeacon Basics: Sending Ads With iBeacon


Unlike most i-Products, iBeacon is not a physical device. Rather, it is a bluetooth protocol. It allows a device to transmit a small amount of information to another device when they are in close proximity (20m max) of each other. A good way to look at an iBeacon is as a lighthouse. An Observer first needs to know what direction to look in. Once an observer can see the light, he/she can determine color of the light and the frequency with which it rotates. They can also roughly determine how near/far they are from the source. However, with both iBeacons and lighthouses, the source and observer cannot communicate furhter without an external technology. In the case of the lighthouse, a great candidate is a radio. In the case of iBeacons, a great cadidate is PubNub.

In the next two tutorials, I will demonstrate how to use an iDevice as both an iBeacon emitter and an iBeacon observer utilizing the programming language Swift. For these examples, we will pretend that the emitter device is being used by a shopkeeper to send daily deals to observer devices running the store's app.

##The General Model


##Our Ad Server
For the purpose of this example, the iOS device emitting the iBeacon will also host this simple ad server for that iBeacon. However, this server code could easily be implemented on an independent machine subscribed to multiple iBeacon's channels. This would be useful when serving ads for many iBeacons or when the emitter device's only functionality is emitting an iBeacon signal.

```swift
class Server: NSObject, PNDelegate {
    let config = PNConfiguration(forOrigin: "pubsub.pubnub.com", publishKey: "demo", subscribeKey: "demo", secretKey: nil)
    let channel = PNChannel.channelWithName("minor:9major:6ChangeThisSuffix", shouldObservePresence: true) as PNChannel
    
    var serverStatus = UILabel()
}
```
Our server class requires PNConfiguration and PNChannel objects to use setup the communication channel for our iBeacon. The channel name should include the major and minor identification numbers you plan to transmit with your iBeacon. We also will use the serverStatus UILabel to provide updates to the user. Remember to iindicate your class is a PNDelegate or else the setDelegate call in the next section will throw an error.

```swift
func setup(serverLabel: UILabel) {
	self.serverStatus = serverLabel
	PubNub.setDelegate(self)
	PubNub.setConfiguration(self.config)
	PubNub.connect()
	PubNub.subscribeOnChannel(self.channel)
}
```
The setup method is called by the UIViewController to trigger the server to connect to the PubNub service and subscribe to the iBeacon's channel. The caller tells us which label to use for status updates in the upcoming delegate functions. The label must be assigned before the PubNub setup calls because it will be updated by delegate functions as setup occurs.

```swift
func pubnubClient(client: PubNub!, didConnectToOrigin origin: String!) {
	self.serverStatus.text = "Connected to PubNub"
}

func pubnubClient(client: PubNub!, didSubscribeOnChannels channels: NSArray!) {
	self.serverStatus.text = "Ready to transmit"
}

func pubnubClient(client: PubNub!, subscriptionDidFailWithError error: PNError!){
	println("Subscribe Error: \(error)")
	self.pubStatus.text = "Subscription Error"
}

func pubnubClient(client: PubNub!, didUnsubscribeOnChannels channels: NSArray!) {
	self.serverStatus.text = "Unsubscribed"
}

func pubnubClient(client: PubNub!, didDisconnectFromOrigin origin: String!) {
	self.serverStatus.text = "Disconnected"
}
```
These methods all update the server status label depending on the results of the actions made in the previous section. They also output subscription erros to the console. They are all delegate methods meaning that they will be automatically called when the type of event they describe occurs.

```swift
func pubnubClient(client: PubNub!, didReceivePresenceEvent event: PNPresenceEvent!) {
	if(event.type.value == PNPresenceEventType.Join.value) {
		PubNub.sendMessage("Free Latte!", toChannel: event.channel)
	}
}
```
Like the methods above, this method is a delegate method. However, it is called whenever a presence event occurs on the iBeacon's channel. Here, it sends the ad information indended for an observer whenever one joins the channel and ignores all other event types (i.e. a user leaves the channel, a user times out). In this example, the information is the deal of the day's text. However, this could be replaced with a push notification trigger, a link to an ad/deal, or any other action that should happen when a user interacts with a channel.

```swift
func pubnubClient(client: PubNub!, didSendMessage message: PNMessage!) {
	println("sent message on channel: \(channel.description)")
}

func pubnubClient(client: PubNub!, didFailMessageSend message: PNMessage!, withError error: PNError!) {
	println(error.description)
}
```
These methods are one again delegate methods. However, they don't update the status label. They merely log message sends/failures on the console.

And there you have it. A simple working iBeacon ad server.

##The iBeacon Emitter
In this example, our UIView requires 6 labels and a button. The labels are used to display the iBeacon's UUID, Major and Minor ID numbers, it's Identity, our beacon's status, and PubNub's status. The button is used to begin the iBeacon's transmission. We also create a delegate class named Server which controls the bulk of our interaction with the PubNub SDK. In addition to the PubNub iOS SDK we will utilize the CoreLocation and CoreBluetooth libraries.

in our UIViewController, we define the following variables:
```swift
	// our UIView's label referencing outlets
    @IBOutlet var uuid : UILabel
    @IBOutlet var major : UILabel
    @IBOutlet var minor : UILabel
    @IBOutlet var identity : UILabel
    @IBOutlet var beaconStatus : UILabel
    @IBOutlet var pubStatus : UILabel
    
    // the UUID our iBeacons will use
    let uuidObj = NSUUID(UUIDString: "0CF052C2-97CA-407C-84F8-B62AAC4E9020")
    
    // Objects used in the creation of iBeacons
    var region = CLBeaconRegion()
    var data = NSDictionary()
    var manager = CBPeripheralManager()
    
    // An instance of our server class
    var srvr = Server()
```
