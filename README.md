#Smart iBeacons in the Swift Programming Language

You can find an xCode project with the code (as one app with both observer and emitter functionality) in this tutorial [on my github][1].

Unlike most iProducts, iBeacon is not a physical device. Rather, it is a bluetooth protocol. It allows a device to transmit a small amount of information to another device when they are in close proximity (20m max) of each other. A good way to look at an iBeacon is as a lighthouse. An observer first needs to know in what direction to look. Once an observer can see the light, he/she can determine color of the light and the frequency with which it rotates. He can also roughly determine how near/far they are from the source. However, with both iBeacons and lighthouses, the source and observer cannot communicate any further without an external technology. In the case of the lighthouse, a great candidate is a radio. In the case of iBeacons, a great candidate is PubNub.

By default, the only information an iBeacon can send to an observer is a set of two numbers (the major and minor numbers). An observer can also determine its rough proximity (far = greater than 10m away, near = within a few meters, immediate = within a couple centimeters) to a beacon and act accordingly. The driving idea behind a smart iBeacon is that one usually wants a beacon to send an observer more information than this limited set. This is accomplished by using the two numbers provided by an iBeacon with a PubNub channel to allow a device to act as the brains of the beacon. An observer uses the iBeacon's information to subscribe to a PubNub channel to which the "brain" device is already listening. That brain device can detect this subscription and initiate complex communication or trigger almost any sort of event.

In this tutorial, I will demonstrate how to use an iDevice as both a smart iBeacon emitter and an iBeacon observer using the programming language Swift. For this example, we will pretend that we are shopkeepers trying to send daily deals to customers running the store's app. The "brain" is an ad server which publishes a deal whenever it detects a new device on the iBeacon's designated channel. When an observer device gets close enough to an iBeacon emitter, it uses the beacon's information to subscribe to the iBeacon's channel, receive the brain's ad, then leave the channel.

//for the titles, say what's going to happen
###The Brains of the iBeacon: A Simple Ad Server
In this example, the iOS device emitting the iBeacon will also host the ad server "brain" for that iBeacon. However, this code could easily be implemented on an independent machine. This independence is useful when one device needs to handle events for many iBeacons (and in turn many possible channels) or when the emitter device's only capability is emitting an iBeacon signal.

```swift
class Brain: NSObject, PNDelegate {
    let config = PNConfiguration(forOrigin: "pubsub.pubnub.com", publishKey: "demo", subscribeKey: "demo", secretKey: nil)
    var channel = PNChannel()
    
    var serverStatus = UILabel()
    
    init() {
    	super.init()
    }
}
```
Our Brain class requires PNConfiguration and PNChannel objects to setup the communication channel for our iBeacon. The channel name should include the major and minor identification numbers you plan to transmit with your iBeacon. We also will use the serverStatus UILabel to provide updates to the user. Remember to indicate your class is a PNDelegate or else the setDelegate call in the next section will throw an error.

```swift
func setup(serverLabel: UILabel, minor: NSNumber, major: NSNumber) {
	self.serverStatus = serverLabel
	PubNub.setDelegate(self)
	PubNub.setConfiguration(self.config)
	PubNub.connect()
	channel = PNChannel.channelWithName("minor:\(minor)major:\(major)CompanyName", shouldObservePresence: true) as PNChannel
	PubNub.subscribeOnChannel(self.channel)
}
```
The setup method is called by the UIViewController to trigger the brain to connect to the PubNub service and subscribe to the iBeacon's channel. The caller tells us which label to use for status updates in the upcoming delegate functions. The label must be assigned before the PubNub setup calls because it will be updated by delegate functions as setup occurs. The setup function also receives a major and minor number. These numbers will be broadcast by the emitter with which the brain is associated.

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
These methods are once again delegate methods. However, they don't update the status label. They merely log message sends/failures on the console.

If you wanted to get rid of the logging/label updating, your one beacon brain could function with less than 20 lines of code: 

```swift
class Server: NSObject, PNDelegate {
    let config = PNConfiguration(forOrigin: "pubsub.pubnub.com", publishKey: "demo", subscribeKey: "demo", secretKey: nil)
    let channel = PNChannel.channelWithName("minor:6major:9CompanyName", shouldObservePresence: true) as PNChannel
    //because you decide on major/minor numbers anyway, you can hardcode them into the channel string.
    
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

###Broadcasting an iBeacon
Moving onto the beacon itself, we simply define the major and minor numbers, set a unique string that our observers will use to find the beacon, make sure that bluetooth is on, and transmit the beacon signal.

In this example, our emitter's UIView uses 6 labels and a button. The labels are used to display the iBeacon's UUID, Major and Minor ID numbers, it's Identity, our beacon's status, and PubNub's status. The button is used to begin the iBeacon's transmission. We also create a Brain object which receives control when an observer is close enough to a beacon. To create the iBeacon, we will utilize the CoreLocation and CoreBluetooth libraries.

in our UIViewController, we define the following variables:
```swift
class ViewController: UIViewController, CBPeripheralManagerDelegate {
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
Once again, remember to include the delegate indication when declaring the class. An observer device is only able to find an iBeacon if it knows the beacon's UUID. You can generate a UUID by using the uuidgen command in terminal. Be sure to use the UUID here and in the observer part of this tutorial. You should also remember to create the labels on your view and connect them to the outlet objects you define in this section.

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    self.region = CLBeaconRegion(proximityUUID: uuidObj, major: 9, minor: 6, identifier: "com.pubnub.test")
    updateInterface()
    
    brain.setup(self.serverStatus, minor: self.region.minor, major: self.region.major)
}
```
In the viedDidLoad() method, we define the beacon region using the previously defined UUID and the major/minor numbers which will be broadcast by the brain. The updateInterface call will update our UILabels to reflect the region we defined.

```swift
func updateInterface(){
    self.uuid.text = self.region.proximityUUID.UUIDString
    self.major.text = "\(self.region.major)"
    self.minor.text = "\(self.region.minor)"
    self.identity.text = self.region.identifier
}
```
Once again, updateInterface simply uses the properties we defined for the region to update the user interface.

```swift
@IBAction func transmitBeacon(sender : UIButton) {
    self.data = self.region.peripheralDataWithMeasuredPower(nil)
    self.manager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
}
```
This IBAction function hooks up to our transmit button. The first call designates our NSDictionary as the data backing the beacon. The second defines our blutooth manager with the UIViewController class we just wrote as its delegate. Defining the bluetooth manager allows us to determine what happens when a bluetooth related event occurs. The delegate class must have one mandatory method (which is coincidentally the only one we need). One again, remember to connect this function to the button on your view.

```swift
func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
    if(peripheral.state == CBPeripheralManagerState.PoweredOn) {
        println("powered on")
        self.manager.startAdvertising(data)
        self.beaconStatus.text = "Transmitting!"
    } else if(peripheral.state == CBPeripheralManagerState.PoweredOff) {
        println("powered off")
        self.manager.stopAdvertising()
        self.beaconStatus.text = "Power Off"
    }
}
```
This delegate method is called when the device's bluetooth changes state (including when the manager is defined). In addition to updating the beacon status label and outputting some logging messages to consol, it basically advertises the beacon when the device's bluetooth is on and stops advertising when it is off.

Now we've completed the code for the emitter device. Before you test it, remember to make sure your device has an internet connection and that it's bluetooth hardwear is on. Another note is that iBeacons only work on devices equipped with bluetooth 4.0 or higher. In the app, merely wait for the server status to display "ready to transmit" then press the transmit button. Voila, you have a working smart iBeacon emitter.

###Observing the Beacon From Another Device
Now that we've made an iBeacon emitter, we'll move on to the code running on the observer devices. It follows that the code in this and the next section runs independently from the the code in the previous two sections. That said, the observer follows a model similar to the emitter. The viewController handles the iBeacon's detection while another class (which we will call the customer) receives control once a beacon's information is harvested. To create the observer, we utilize the CoreLocation and CoreBluetooth libraries.

```swift
class ViewController: UIViewController, CLLocationManagerDelegate {
    //our status label's referencing outlets
    @IBOutlet var found : UILabel
    @IBOutlet var uuid : UILabel
    @IBOutlet var major : UILabel
    @IBOutlet var minor : UILabel
    @IBOutlet var accuracy : UILabel
    @IBOutlet var distance : UILabel
    @IBOutlet var rssi : UILabel
    @IBOutlet var deal : UILabel
    @IBOutlet var pubStatus : UILabel
    
    //our UUID, make sure it's the same as the one you used for the emitter above
    let uuidObj = NSUUID(UUIDString: "0CF052C2-97CA-407C-84F8-B62AAC4E9020")
    
    //the core library objects used to detect iBeacons
    var region = CLBeaconRegion()
    var manager = CLLocationManager()
    
    //our customer object
    var cstmr = Customer()
}
```
The UILabels are all used for the purpose of this demo to display information about the iBeacon our observer device detects. Similarly, one of the labels allows the PubNub delegate class (Customer) to update the status the connection to PubNub. It also has a label used to display the deal retreived from the iBeacon emitter. The found label is used to update the status of the observer component of this code (i.e. we've found a beacon, we're looking for one, etc.).  We still have our iBeacon libraries and a customer object. We also still have a UUID object - make sure it's the same as the one used in the emitter.

```swift
override func viewDidLoad() {
	super.viewDidLoad()
	manager.delegate = self
	region = CLBeaconRegion(proximityUUID: uuidObj, identifier: "com.pubnub.test")
	
	cstmr.setup(deal, pubStatus: pubStatus)
}
```
In the viewDidLoad method, we set the viewController as the delegate for the location manager. We also define a beacon region using the identifier and uuid we used with the emitter. We also call the setup method of our customer object (to be detailed in the next section).

```swift
@IBAction func startDetection(sender : UIButton) {
	if(UIDevice.currentDevice().systemVersion.substringToIndex(1).toInt() >= 8){
		self.manager.requestAlwaysAuthorization()
	}
	self.manager.startMonitoringForRegion(self.region)
	self.found.text = "Starting Monitor"
}
```
Once our connection to PubNub has been setup by the Customer.setup method, we hit the start detection button. The action method it calls begins looking for an iBeacon and updates the monitoring status (found) label accordingly. The if statmenet contains a location authorization request required in iOS 8 and later. However, calling it in an older iOS crashes the program. Thus, we need to check our iOS version and make sure we call it if and only if our device is running iOS 8 or later. 

```swift
func locationManager(manager: CLLocationManager!, didStartMonitoringForRegion region: CLRegion!) {
	self.found.text = "Scanning..."
	manager.startRangingBeaconsInRegion(region as CLBeaconRegion) //testing line
}

func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
	manager.startRangingBeaconsInRegion(region as CLBeaconRegion)
	self.found.text = "Possible Match"
}
    
func locationManager(manager: CLLocationManager!, monitoringDidFailForRegion region: CLRegion!, withError error: NSError!) {
	self.found.text = "Error :("
	println(error)
}

func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
	manager.stopRangingBeaconsInRegion(region as CLBeaconRegion)
	reset()
}
```
Under normal iBeacon operation, one should only range beacons once one knows they are in a beacon's region. However, the only way to know this is for certain is to enter an iBeacon's region. This is inconvenient because an iBeacon can be detected from up to 20m away. The testing line is placed in the didStartMonitoringForRegion method so you don't have to leave the building every time you want to test your code. The didEnterRegion method begins ranging beacons whenever a user enters an iBeacon region. The monitoringDidFailForRegion prints errors to console. Finally, the didExitRegion method resets the state variables the customer class uses and stops beacon ranging. All of these methods update our status text accordingly.

```swift
func reset(){
	self.found.text = "No"
	self.uuid.text = "N/A"
	self.major.text = "N/A"
	self.minor.text = "N/A"
	self.accuracy.text = "N/A"
	self.rssi.text = "N/A"

	cstmr.needDeal = true
	cstmr.subscribeAttempt = true
	self.deal.text = "Come on down to PubNub Cafe for a hot deal!"
}
```
Our reset method is used when we want to reset the state variables used by the customer and the labels. (i.e. when we leave the beacon's region).

```swift
func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: NSArray!, inRegion region: CLBeaconRegion!) {
	if(beacons.count == 0) { return }
	
	var beacon = beacons.lastObject as CLBeacon
	
	if (beacon.proximity == CLProximity.Unknown) {
		self.distance.text = "Unknown Proximity"
		reset()
		return
	} else if (beacon.proximity == CLProximity.Immediate) {
		self.distance.text = "Immediate"
		cstmr.getAdOfTheDay(beacon.major, minor: beacon.minor)
	} else if (beacon.proximity == CLProximity.Near) {
		self.distance.text = "Near"
		//reset()
	} else if (beacon.proximity == CLProximity.Far) {
		self.distance.text = "Far"
	}
	self.found.text = "Yes!"
	self.uuid.text = beacon.proximityUUID.UUIDString
	self.major.text = "\(beacon.major)"
	self.minor.text = "\(beacon.minor)"
	self.accuracy.text = "\(beacon.accuracy)"
	self.rssi.text = "\(beacon.rssi)"
    }
```
The didRangeBeacons delegate method is called when we have ranged a set of beacons who's regions we are currently occupying. It gives us an array of beacons, but for now we are only looking at one. The first line of the method exists because of our testing call to "startRangingBeacons" so we don't segfault when referencing an empty object. This might occur when we start the app out of range of any beacons. The rest of this method updates the labels to reflect current information about the beacon we are receiving data from. Officially, it can take up to 20 seconds to accurately display beacon information, but in practice it takes about 3. Right now, we hand control over to the customer object when our distance is immediate. It is easier to test the customer object when we reset our state at the "near" distance as opposed to when we leave the beacon's region.

###Receiving the Ads
Our customer class handles the observer's communication with the emitter beacon's brain. Once it receives control from the view controller, it uses the information obtained from the iBeacon to subscribe to the channel which the brain is monitoring. Once it receives a message from the brain, the customer displays the contents of the message, in this case an ad/deal, then unsubscribes.

```swift
class Customer: NSObject, PNDelegate {
    
    let config = PNConfiguration(forOrigin: "pubsub.pubnub.com", publishKey: "demo", subscribeKey: "demo", secretKey: nil)
    
    var connected = false
    var deal = UILabel()
    var pubStatus = UILabel()
    var needDeal = true
    var subscribeAttempt = true
    
    init(){
        super.init()
    }
}
```
Our customer class maintains control over two labels. One to display the ad it receives from the iBeacon and the other to send status updates. It also requires some state variables to prevent itself from continuously subscribing to the channel and processing messages while within the threshold range of the iBeacon.

```swift
func setup(deal: UILabel, pubStatus: UILabel) {
	self.deal = deal
	self.pubStatus = pubStatus
	PubNub.setDelegate(self)
	PubNub.setConfiguration(self.config)
	PubNub.connect()
}
```
The setup method connects the customer to PubNub and sets itself as the delegate class. It also sets the ad and status update labels.

```swift
func getAdOfTheDay(major: NSNumber, minor: NSNumber) {
	if(connected && subscribeAttempt) {
	subscribeAttempt = false
	var channel: PNChannel = PNChannel.channelWithName("minor:\(minor)major:\(major)CompanyName", shouldObservePresence: true) as PNChannel
	PubNub.subscribeOnChannel(channel)
	} else if (subscribeAttempt) {
	deal.text =  "connection error :("
	}
}
```
The getAdOfTheDay method attempts to subscribe to the iBeacon's channel utilizing the major and minor numbers observed by the viewController. However, it makes sure that the observer is connected to PubNub and that it hasn't already attempted to subscribe. If there is no connection when subscribeAttempt is true, it displays an error.

```swift
func pubnubClient(client: PubNub!, didReceiveMessage message: PNMessage!){
	println("message received!")
	self.pubStatus.text = "Deal Received"
	if(needDeal) {
		self.needDeal = false
		self.deal.text = "\(message.message)"
	}
	PubNub.unsubscribeFromChannel(message.channel)
}
```
Once the customer is subscribed to the channel, it should almost immediately receive a message from the brain. The didReceiveMessage delegate method is called when said message is received. It outputs the receipt to console and updates the status text. The method checks to make sure it hasn't already received a deal before updating the view. It then unsubscribes from the iBeacon's channel.

```swift
func pubnubClient(client: PubNub!, didConnectToOrigin origin: String!) {
	println("connected to origin \(origin)")
	connected = true
	self.pubStatus.text = "connected"
}

func pubnubClient(client: PubNub!, didSubscribeOnChannels channels: NSArray!) {
	println("Subscribed to channel(s): \(channels)")
	self.pubStatus.text = "Subscribed"
}

func pubnubClient(client: PubNub!, didUnsubscribeOnChannels channels: NSArray!) {
	println("Unsubscribed from channel(s): \(channels)")
	self.pubStatus.text = "Unsubscribed"
}

func pubnubClient(client: PubNub!, subscriptionDidFailWithError error: PNError!){
	println("Subscribe Error: \(error)")
	self.pubStatus.text = "Subscription Error"
}
```
These functions merely update the status label and print logging info to the console. The didConnectToOrigin delegate method switches the connected boolean to true, but the other methods could theoretically be removed without affecting the class' functionality.

Between these four classes, you should have a working iBeacon capable of complex communication with its observers. From here, you can modify the communication model to anything from multi-device chat to location based authentication (i.e. unlock a door when in proximity to an iBeacon). Enjoy!

[1]: http://www.github.com/ertheis/Smart-iBeacon
