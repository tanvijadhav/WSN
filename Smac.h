#ifndef SMAC_H
#define SMAC_H

typedef nx_struct datapkt
{
	nx_uint16_t NodeId;
	nx_uint16_t Data;
}datapkt_t;

typedef nx_struct syncpkt
{
	nx_uint16_t Node_Id;
	nx_uint32_t TimeToData;
	nx_uint32_t DataDuration;
	//nx_uint8_t SleepTime;
}syncpkt_t;

typedef nx_struct normal
{
	nx_uint16_t NodeId;
	nx_uint8_t Data;
}normal_t;

typedef nx_struct tmstmp
{
	//nx_uint16_t NodeId;
	nx_uint32_t T1;
	nx_uint32_t T4[6];
}tmstmp_t;

enum
{
	AM_RADIO=6
};



#endif /* SMAC_H */
