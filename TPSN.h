#ifndef TPSN_H
#define TPSN_H
typedef nx_struct normal
{
	nx_uint16_t NodeId;
	nx_uint8_t Data;
}normal_t;

typedef nx_struct tmstmp
{
	nx_uint16_t NodeId;
	nx_uint32_t T1;
	nx_uint32_t T4[4];
}tmstmp_t;

enum
{
	AM_RADIO=6
};
#endif /* TPSN_H */
