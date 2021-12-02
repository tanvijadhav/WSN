#include<UserButton.h>
#include "TPSN.h"
#include "printf.h" 
module TPSNC{
	uses
	{
		interface Leds;
		interface Boot;
		interface Timer<TMilli> as Timer0;
		//interface Timer<TMilli> as Tdma;
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
implementation{
	message_t pkt;
	uint8_t i;
	uint8_t lim=0;
	bool radioBusy=FALSE;
	uint8_t state=0;
	uint8_t state2=0;
	int clkoffs = 0;
	tmstmp_t* tmstmpPkt;
	//normal_t* reply;
	normal_t* normalPkt;
	//tmstmp_t* tim;
	uint32_t Tx[2] = {0,0}, Rx[2] = {0,0};
	uint32_t T4s[4]={10,20,30,40}; // Maybe error here;
	uint32_t tstp;
	event void Boot.booted(){
		// TODO Auto-generated method stub
		call AMControl.start();
		call Notify.enable();
	}

	event void Timer0.fired(){
		// TODO Auto-generated method stub
		call Timer0.stop();
		/*normal_t**/ normalPkt=call Packet.getPayload(&pkt, sizeof(normal_t));
				normalPkt->NodeId=TOS_NODE_ID;
				normalPkt->Data=1;
				if(call AMSend.send(1, &pkt, sizeof(normal_t))==SUCCESS)
				radioBusy=TRUE;
	}

	event void Notify.notify(button_state_t val){
		// TODO Auto-generated method stub
		state = 0;
		if(/*state==0 && */TOS_NODE_ID==1)
		{
			/*normal_t**/ normalPkt=call Packet.getPayload(&pkt, sizeof(normal_t));
			normalPkt->NodeId=1;
			normalPkt->Data=1;
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(normal_t))==SUCCESS)
			radioBusy=TRUE;
			//state++;
		}
	}

	event void AMControl.startDone(error_t error){
		// TODO Auto-generated method stub
		if(error!=SUCCESS)
		{
			call AMControl.start();	
		}
		else
		call Leds.led0On();
	}

	event void AMControl.stopDone(error_t error){
		// TODO Auto-generated method stub
	}

	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		// TODO Auto-generated method stub
		if(len==sizeof(normal_t))
		{
		normalPkt=(normal_t*) payload;
		printf("Node %d recieved from node %d ",TOS_NODE_ID ,normalPkt->NodeId);
		printfflush();
		}
		if(TOS_NODE_ID!=1 && call Tstamp.isValid(msg))
		{
			if(state2>1 && len==sizeof(tmstmp_t))//Node recieves the final packet with T1 & T4
			{
				/*tmstmp_t**/ tmstmpPkt=(tmstmp_t*) payload;
				Rx[0]=tmstmpPkt->T1;//make changes here
				Rx[1] = tmstmpPkt->T4[TOS_NODE_ID];
				printf("The timestamps are, T1=%ld T2=%ld T3=%ld T4=%ld \n",Rx[0],Tx[0],Tx[1],Rx[1]);
				printfflush();
				clkoffs+= (-Rx[0]+Tx[0]+Tx[1]-Rx[1])/2;
				//printf("The calculated clock skew is %d \n",(-Rx[0]+Tx[0]+Tx[1]-Rx[1])/2);
				//printfflush();
				call Leds.led2On();
				state2 = 0;
				//if(Rx[0] && Rx[1] && Tx[0] && Tx[1])
				//call Leds.led1On();
				//calculating offset
			}
			else//Node 2 sends packet after recieving 1st packet
			{
				Tx[state2++]=call Tstamp.timestamp(msg);//t2
				call Timer0.startPeriodic(TOS_NODE_ID*50);
			}
		}
		
		if(TOS_NODE_ID==1 && call Tstamp.isValid(msg))
		{
		/*	Tx[state++]=call Tstamp.timestamp(msg);//T4
			//normal_t* incomePacket=(normal_t*) payload;
			if(state>1)
			{
				/*tmstmp_t**//* tmstmpPkt=call Packet.getPayload(&pkt, sizeof(tmstmp_t));
				tmstmpPkt->NodeId=1;
				tmstmpPkt->T1=Tx[0];
				tmstmpPkt->T4=Tx[1];
				if(call AMSend.send(2, &pkt, sizeof(tmstmp_t))==SUCCESS)
				radioBusy=TRUE;
			}	*/
			tstp=call Tstamp.timestamp(msg);
			printfflush();
			printf("T4 is %ld",tstp);
			printfflush();
			if(len==sizeof(normal_t));
			{
				lim++;
				normalPkt=(normal_t*) payload;
				T4s[normalPkt->NodeId]=tstp;
			}
			if(lim>2)
			{
				tmstmpPkt=call Packet.getPayload(&pkt, sizeof(tmstmp_t));
				tmstmpPkt->NodeId=1;
				tmstmpPkt->T1=Tx[0];
				for(i = 2;i<5;i++){
					tmstmpPkt->T4[i]=T4s[i];
				}
				
				if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(tmstmp_t))==SUCCESS)
				radioBusy=TRUE;
			}	
		}
		return msg;
	}

	event void AMSend.sendDone(message_t *msg, error_t error){
		// TODO Auto-generated method stub
		radioBusy=FALSE;
		if(call Tstamp.isValid(msg))
		{
			if(TOS_NODE_ID==1)
			Tx[state++]=call Tstamp.timestamp(msg);//T1
			if(TOS_NODE_ID!=1)
			Tx[state2++]=call Tstamp.timestamp(msg);//T3
		}
	}
}