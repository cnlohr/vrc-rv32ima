#ifndef VRC_RV32IMA
#define VRC_RV32IMA

#define SYSTEX_WIDTH 2048
#define SYSTEX_HEIGHT 2048

#define MEMORY_BASE 0x80000000
#define MEMORY_SIZE 0x3FF8000

float4 _SystemMemorySize;


float4 ClipSpaceCoordinateOut( uint2 coordOut, float2 FlexCRTSize )
{
	// I believe these are equivelent. 
	//return float4((coordOut.xy*float2(2,-2)+float2(-2.0*FlexCRTSize.x*0.5+1.5,FlexCRTSize.y-1.5))/FlexCRTSize, 0.5, 1 );
	return float4( coordOut.xy*float2(1,-1)+float2(-FlexCRTSize.x/2+.5,FlexCRTSize.y/2-.5), 0, FlexCRTSize.x/2 );
}


#endif
