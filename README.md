#Smart iBeacons in Swift


Unlike most i-Products, iBeacon is not a physical device. Rather, it is a bluetooth protocol. It allows a device to transmit a small amount of information to another device when they are in close proximity (20m max) of each other. A good way to look at an iBeacon is as a lighthouse. An Observer first needs to know what direction to look in. Once an observer can see the light, he/she can determine color of the light and the frequency with which it rotates. They can also roughly determine how near/far they are from the source. However, with both iBeacons and lighthouses, the source and observer cannot communicate any further without an external technology. In the case of the lighthouse, a great candidate is a radio. In the case of iBeacons, a great cadidate is PubNub.

By default, the only information an iBeacon can send to an observer is a set of two numbers (the major and minor numbers). The basic idea behind a smart iBeacon is that one might want a beacon to send more information than this limited set to an observer. This is accomplished by using the two numbers provided by an iBeacon with PubNub to allow a device to act as the brains of the beacon. An observer uses the iBeacon's information to subscribe to a PubNub channel to which the "brain" device is listening. That brain device can detect this subscription and initiate complex communication or trigger almost any sort of event.

In this tutorial, I will demonstrate how to use an iDevice as both an iBeacon emitter and an iBeacon observer using the programming language Swift. For this example, we will pretend that the iBeacon is being used by a shopkeeper to send daily deals to observer devices running the store's app. The "brain" is an ad server which publishes a deal whenever it detects a new device on the iBeacon's channel. When an observer device gets close enough to an iBeacon, it uses the beacon information to subscribe to the iBeacon's channel, receive the brain's ad, then leave.

###A Simple Ad Server
In this example, the iOS device emitting the iBeacon will also host the ad server "brain" for that iBeacon. However, this code could easily be implemented on an independent machine. This independence is useful when one device needs to handle events for many iBeacons (and in turn many possible channels) or when the emitter device's only capability is emitting an iBeacon signal.

```swift
class Brain: NSObject, PNDelegate {
    let config = PNConfiguration(forOrigin: "pubsub.pubnub.com", publishKey: "demo", subscribeKey: "demo", secretKey: nil)
    let channel = PNChannel.channelWithName("minor:6major:9CompanyName", shouldObservePresence: true) as PNChannel
    
    var serverStatus = UILabel()
    
    init() {
    	super.init()
    }
}
```
Our Brain class requires PNConfiguration and PNChannel objects to setup the communication channel for our iBeacon. The channel name should include the major and minor identification numbers you plan to transmit with your iBeacon. We also will use the serverStatus UILabel to provide updates to the user. Remember to indicate your class is a PNDelegate or else the setDelegate call in the next section will throw an error.

```swift
func setup(serverLabel: UILabel) {
	self.serverStatus = serverLabel
	PubNub.setDelegate(self)
	PubNub.setConfiguration(self.config)
	PubNub.connect()
	PubNub.subscribeOnChannel(self.channel)
}
```
The setup method is called by the UIViewController to trigger the brain to connect to the PubNub service and subscribe to the iBeacon's channel. The caller tells us which label to use for status updates in the upcoming delegate functions. The label must be assigned before the PubNub setup calls because it will be updated by delegate functions as setup occurs.

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

If you wanted to get rid of the logging/label updating, your one beacon brain could function with less than 20 lines of code: 

```swift
class Server: NSObject, PNDelegate {
    let config = PNConfiguration(forOrigin: "pubsub.pubnub.com", publishKey: "demo", subscribeKey: "demo", secretKey: nil)
    let channel = PNChannel.channelWithName("minor:6major:9CompanyName", shouldObservePresence: true) as PNChannel
    
    var serverStatus = UILabel()
    
    init() {
    	super.init()
		self.serverStatus = serverLabel
		PubNub.setDelegate(self)
		PubNub.setConfiguration(self.config)
		PubNub.connect()
		PubNub.subscribeOnChannel(self.channel)
	}
	
	func pubnubClient(client: PubNub!, didReceivePresenceEvent event: PNPresenceEvent!) {
		if(event.type.value == PNPresenceEventType.Join.value) {
		    //you can modify the following line to send whatever information you want to the observer.
		    //you could also initiate an action such as a push notification.
			PubNub.sendMessage("Free Latte!", toChannel: event.channel)
		}
	}
}
```

And there you have it. A simple working iBeacon brain.

###The iBeacon Emitter
Moving onto the beacon itself, we simply define the major and minor numbers, set a unique string that our observers will use to find the beacon, make sure that bluetooth is on, and transmit the beacon signal.

In this example, our emitter's UIView uses 6 labels and a button. The labels are used to display the iBeacon's UUID, Major and Minor ID numbers, it's Identity, our beacon's status, and PubNub's status. The button is used to begin the iBeacon's transmission. We also create a Brain object which receives control when an observer is close enough to a beacon. In addition to the PubNub iOS SDK we will utilize the CoreLocation and CoreBluetooth libraries.

in our UIViewController, we define the following variables:
```swift
class beViewController: UIViewController, CBPeripheralManagerDelegate {
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
}
```
Once again, remember to include the delegate indication when declaring the class. An observer device is only able to find an iBeacon if it knows the beacon's UUID. You can generate a UUID by using the uuidgen command in terminal. Be sure to use the UUID here and in the observer part of this tutorial.

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    self.region = CLBeaconRegion(proximityUUID: uuidObj, major: 9, minor: 6, identifier: "com.pubnub.test")
    updateInterface()
    
    brain.setup(self.serverStatus)
}
```
In the viedDidLoad() method, we define the beacon region using the previously defined UUID and the major/minor numbers you chose in the brain section above. The update interface call will update our UILabels to reflect the region we defined. If your brain has a setup method, call it here.

```swift
func updateInterface(){
    self.uuid.text = self.region.proximityUUID.UUIDString
    self.major.text = "\(self.region.major)"
    self.minor.text = "\(self.region.minor)"
    self.identity.text = self.region.identifier
}
```
Here we simply use the properties we defined for the region to update the user interface.

```swift
@IBAction func transmitBeacon(sender : UIButton) {
    self.data = self.region.peripheralDataWithMeasuredPower(nil)
    self.manager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
}
```
This IBAction function hooks up to our transmit button. The first call designates our NSDictionary as the data backing the beacon. The second defines our blutooth manager with the UIViewController class we just wrote as its delegate. Defining the bluetooth manager allows us to determine what happens when a bluetooth related event occurs. The delegate class must have one mandatory method (which is coincidentally the only one we need).

```swift
func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
    if(peripheral.state == CBPeripheralManagerState.PoweredOn) {
        println("powered on")
        println(data)
        self.manager.startAdvertising(data)
        self.beaconStatus.text = "Transmitting!"
    } else if(peripheral.state == CBPeripheralManagerState.PoweredOff) {
        println("powered off")
        self.manager.stopAdvertising()
        self.beaconStatus.text = "Power Off"
    }
}
```
This delegate method is called when the device's bluetooth changes state (including when the manager is defined). 
