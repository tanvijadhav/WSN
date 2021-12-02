#include "printf.h"
#include "TPSN.h"

configuration TPSNAppC{
	
}
implementation{
	components PrintfC;
	components SerialStartC;
	components TPSNC as App;
	components MainC;
	components LedsC;
	components new TimerMilliC() as Timer;
	
	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Timer0->Timer;
	//App.Timer1->Timer;
	
	components UserButtonC;
	App.Get -> UserButtonC;
	App.Notify -> UserButtonC;
	
	//Radio
	components ActiveMessageC;
	components new AMSenderC(AM_RADIO);
	components new AMReceiverC(AM_RADIO);
	
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.Receive-> AMReceiverC;
	App.Tstamp -> ActiveMessageC;
}