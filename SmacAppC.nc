
#include "printf.h"
#include "Smac.h"

configuration SmacAppC
{
}
implementation
{
	components PrintfC;
	components SerialStartC;
	components SmacC as App;
	components MainC;
	components LedsC;
	components new TimerMilliC() as Tsync;
	components new TimerMilliC() as Tdata;
	components new TimerMilliC() as Tsleep;
	components new TimerMilliC() as Timeout;
	//components new TimerMilliC() as Tdma;
	components new TimerMilliC() as Delay;
	components new TimerMilliC() as Delay2;
	components new TimerMilliC() as Delay3;
	components new TimerMilliC() as Timesync;
	components new TimerMilliC() as TsyncTdma;
	components new TimerMilliC() as Timer0;

	
	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Tsync->Tsync;
	App.Tsleep->Tsleep;
	App.Timeout->Timeout;
	App.Tdata->Tdata;
	//App.Tdma->Tdma;
	App.Delay->Delay;
	App.Delay2->Delay2;
	App.Delay3->Delay3;
	App.Timesync->Timesync;
	App.TsyncTdma -> TsyncTdma;
	App.Timer0->Timer0;
	
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