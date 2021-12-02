/*
@authors: Edwin Mascarenhas
		  Abuturab Mohammadi
		  Vedangi Pathak
		  Pranav Pal Lekhi
		  Tanvi Jadhav

Under the Esteemed guidence of Prof K.R Anupama, faculty EEE & I department
BITS Pilani, K.K Birla Goa campus
This code has been tested with 4 motes.
have been added to the network at a later stage
This program should work for more motes too with some changes in the TDMA cycle. However it hasn't been tested so far.
*/

#include "Smac.h"
#include <UserButton.h>
#include "printf.h"

//different modules used
module SmacC
{
	uses 
	{
		interface Boot;
		interface Leds;
		interface Timer<TMilli> as Tsync;
		interface Timer<TMilli> as Tdata;
		interface Timer<TMilli> as Tsleep;
		interface Timer<TMilli> as Timeout;
		interface Timer<TMilli> as Delay;
		interface Timer<TMilli> as Delay2;
		interface Timer<TMilli> as Timesync;
		interface Timer<TMilli> as TsyncTdma;
		interface Timer<TMilli> as Delay3;

		interface Timer<TMilli> as Timer0; //new

	}
	uses 
	{
		interface Get<button_state_t>;
		interface Notify<button_state_t>;
	}
	uses
	{
		interface Packet;
		interface AMPacket;
		interface SplitControl as AMControl;
		interface Receive;
		interface AMSend;
		interface PacketTimeStamp<TMilli,uint32_t> as Tstamp;
	}
}

//Implementation of code
implementation
{	
	//variable declarations
	uint16_t nodeHead;
	message_t pkt;
	bool radioBusy=FALSE;	
	bool head = FALSE;
	uint32_t timetodata;
	uint32_t datatime;
	uint32_t sleepperiod = 1000;
	syncpkt_t* sync_packet;
	datapkt_t* info;
	uint32_t delay = 20;
	uint32_t delay2 = 20;
	uint8_t state = 0,state2 = 0;
	normal_t* normalPkt;
	tmstmp_t* tmstmpPkt;
	int32_t Tx[2] = {0,0}, Rx[2] = {0,0};
	uint32_t T4s[6]={10,10,10,10,10,10};
	uint32_t tstp;
	int clkoffs = 0;
	uint8_t lim=0;
	int delta1 = 0,delta2 = 0;
	int count = 0;

	uint8_t i,count1=0,count2=0,count3=0,count_timer=1,cnt=0; //new
	uint8_t Rec[8]={0,0,0,0,0,0,0,0};
	uint32_t weight[8];
	uint32_t x[8]={1,100,100,1,1,100,100,1};
	uint32_t y[8]={1,1,100,100,500,600,600,500};
	//uint32_t x1[4]={1000,100,100,1};
	//uint32_t y1[4]={};
	uint32_t Ynew = 0, Xnew = 0;
	int n=50;
	uint32_t densum = 0, numsumx = 0,numsumy = 0; 


	//After booting
	event void Boot.booted(){
		call Leds.led2On();
		call AMControl.start();
		call Timeout.startPeriodic(2050);
	}


	event void Delay.fired(){

		call Delay.stop();
		
			call Timesync.startPeriodic(500);
			normalPkt=call Packet.getPayload(&pkt, sizeof(normal_t));
			normalPkt->NodeId=TOS_NODE_ID;
			normalPkt->Data=1;
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(normal_t))==SUCCESS)
			radioBusy=TRUE;
	}

	event void Delay2.fired(){
		call Delay2.stop();
		call AMControl.stop();
		call Tsleep.startPeriodic(sleepperiod);
	}


	event void Delay3.fired(){
		call Delay3.stop();

		sync_packet=call Packet.getPayload(&pkt, sizeof(syncpkt_t));
			sync_packet->Node_Id = TOS_NODE_ID;
			sync_packet->DataDuration = 1000;
			sync_packet->TimeToData = 500 - (call Tsync.getNow());
		if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(syncpkt_t))==SUCCESS)
				{
					radioBusy=TRUE;
				}
	}

	//after period of one entire frame is over
	event void Timeout.fired(){
		call Timeout.stop();
		head = TRUE;
		datatime = 1000;
		call Tsync.startPeriodic(500);
		sync_packet=call Packet.getPayload(&pkt, sizeof(syncpkt_t));
		sync_packet->Node_Id = TOS_NODE_ID;
		sync_packet->DataDuration = 1000;
		sync_packet->TimeToData = 500 - (call Tsync.getNow());
		if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(syncpkt_t))==SUCCESS)
				{	
					radioBusy=TRUE;
				}	
	}

	//When the sync period is over
	event void Tsync.fired(){
		call Tsync.stop();
		call Tdata.startPeriodic(1000);
			if(TOS_NODE_ID==1||TOS_NODE_ID==2|| TOS_NODE_ID==3 || TOS_NODE_ID ==4 || TOS_NODE_ID ==5 || TOS_NODE_ID ==6 || TOS_NODE_ID ==7 || TOS_NODE_ID ==8)
			{
				call Timer0.startPeriodic(20); //new
			}
		
						
	}

	event void Timer0.fired() //new
	{
		//call Timer0.stop(); //
		if(count_timer<=n)
		{
			count_timer++;
			if (radioBusy==FALSE)
			
			{
				datapkt_t* msg=call Packet.getPayload(&pkt, sizeof(datapkt_t));
				msg->NodeId=TOS_NODE_ID;
				msg->Data=1;

				if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(datapkt_t))==SUCCESS)
				{
					radioBusy=TRUE;
				}

			}

		}

		if(count_timer>n)
		{
			count_timer=1;
			call Timer0.stop();
		}
	}


	//When the data period is over
	event void Tdata.fired(){
		if(call Timer0.isRunning())
			call Timer0.stop();
		call Tdata.stop();
		if(head){
			call Delay2.startPeriodic(delay2);
		}		
		else{
			call AMControl.stop();
			call Tsleep.startPeriodic(sleepperiod);
		}	
	}

	//after timesync is over
	event void Timesync.fired(){
		//call Leds.led1Toggle();
		call Timesync.stop();
		if(head){
			tmstmpPkt=call Packet.getPayload(&pkt, sizeof(tmstmp_t));
				tmstmpPkt->T1=Tx[0];
				for(i = 0;i<6;i++){
					tmstmpPkt->T4[i]=T4s[i];
				}
				
				if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(tmstmp_t))==SUCCESS)
				radioBusy=TRUE;
		}
		call Tsync.startPeriodic(500);
		if(head){
			call Delay3.startPeriodic(30);
		}
		
	}

	//When sleep period is over
	event void Tsleep.fired(){
		call Tsleep.stop();
		state = 0;
		state2 = 0;
		call AMControl.start();
		
		if(!head){
			call Timesync.startPeriodic(500);
		}
		
		
	}

	event void Notify.notify(button_state_t val){
	}

	//If packet is recieved
	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		if(sizeof(syncpkt_t) == len){
			if(call Timeout.isRunning()){
				call Timeout.stop();
			}
			if(!head){
				if(call Tsync.isRunning()){
					call Tsync.stop();
				}
				sync_packet = (syncpkt_t*) payload;
				timetodata = sync_packet->TimeToData;
				datatime = sync_packet->DataDuration;
				nodeHead=sync_packet->Node_Id;
				call Tsync.startPeriodic(500);
			}
		}

		if(TOS_NODE_ID==9) //new
		{
			if(len==sizeof(datapkt_t))
			{
				datapkt_t* incomePacket=(datapkt_t*) payload;
				uint16_t node= incomePacket->NodeId;
				Rec[node-1]+=1;
				cnt++;
				
				if(cnt>=n)
				{	
				
					cnt=0;
					
					for(i=0;i<8;i++)
					{
						weight[i]=Rec[i];
						Rec[i]=0;
						/*printf("Weight of %d is %ld \n",i+1,weight[i]);
						printfflush();*/
					}
					densum=0;
					numsumx=0;
					numsumy=0;

					for(i=0;i<8;i++)
					{
						
						
						densum=densum+weight[i];
						numsumx=numsumx+(weight[i]*x[i]);
						numsumy=numsumy+(weight[i]*y[i]);
						weight[i] = 0;
						
					}
					Xnew=(float)numsumx/(float)densum;
					Ynew=(float)numsumy/(float)densum;
					printf("X coordinate %ld \n",Xnew);
					printfflush();
					printf("Y coordinate %ld \n",Ynew);
					printfflush();


				}
			}
		}
		
		
		if(call Timesync.isRunning() && state2<=1 && sizeof(normal_t) == len){
						
				//Node 2 sends packet after receiving 1st packet
					Tx[state2++]=call Tstamp.timestamp(msg);//t2
					call TsyncTdma.startPeriodic(TOS_NODE_ID*50);
			}


			if(!head && call Tstamp.isValid(msg)){
				if(state2>1 && len==sizeof(tmstmp_t))//Node receives the final packet with T1 & T4
				{
					tmstmpPkt=(tmstmp_t*) payload;
					Rx[0]=tmstmpPkt->T1;//make changes here
					if(TOS_NODE_ID >= 5)
						Rx[1] = tmstmpPkt->T4[TOS_NODE_ID -5];
					else
						Rx[1] = tmstmpPkt->T4[TOS_NODE_ID -1];
					printf("The timestamps are, T1=%ld T2=%ld T3=%ld T4=%ld \n",Rx[0],Tx[0],Tx[1],Rx[1]);
					printfflush();

					if(count == 0){
						clkoffs = count;
						delta2 = (int)(Tx[0]-Rx[0]+Tx[1]-Rx[1])/2;
						count++;
					}
					else{
						delta2 = (int)(Tx[0]-Rx[0]+Tx[1]-Rx[1])/2;
						clkoffs = delta2 - delta1;
						
					}
					delta1 = delta2;
					state2 = 0;
					printf("delta is %d",clkoffs);
				}
			}
			if(head && call Tstamp.isValid(msg))
			{
				tstp=call Tstamp.timestamp(msg);
				if(len==sizeof(normal_t));
				{
					normalPkt=(normal_t*) payload;
					if(normalPkt->NodeId >= 5)
					T4s[normalPkt->NodeId - 5]=tstp;
					else
					T4s[normalPkt->NodeId -1]=tstp;
				}
			}
	
		return msg;
	}

	//Other events when radio has started, stopped or finished sending
	event void AMControl.stopDone(error_t error){
		if(error != SUCCESS){
			call AMControl.stop();
		}
	}
	
	event void AMControl.startDone(error_t error){
		if(error != SUCCESS){
			call AMControl.start();
		}
		if(error == SUCCESS){

		if(head){
			call Delay.startPeriodic(delay);
		}
		}
	}

	event void AMSend.sendDone(message_t *msg, error_t error){
		radioBusy = FALSE;
		if(call Timesync.isRunning()){
			if(call Tstamp.isValid(msg))
		{
			if(head)
			Tx[state++]=call Tstamp.timestamp(msg);//T1
			else
			Tx[state2++]=call Tstamp.timestamp(msg);//T3
		}
		}
	}


	event void TsyncTdma.fired(){
		call TsyncTdma.stop();
		/*normal_t**/ normalPkt=call Packet.getPayload(&pkt, sizeof(normal_t));
				normalPkt->NodeId=TOS_NODE_ID;
				normalPkt->Data=1;
				if(call AMSend.send(nodeHead, &pkt, sizeof(normal_t))==SUCCESS)
				radioBusy=TRUE;
	}
}