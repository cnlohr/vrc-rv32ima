#ifndef VRC_RV32IMA
#define VRC_RV32IMA



Texture2D<uint4> _MainSystemMemory;

#define MINI_RV32_RAM_SIZE (1024*1024*16)
#define SYSTEX_SIZE_X 1024
#define SYSTEX_SIZE_Y 1024

#define MEMORY_BASE 0x80000000
#define MEMORY_SIZE 0x3FF8000

float4 _SystemMemorySize;

// For intermediate outputs.
static uint pixelOutputID;

float4 ClipSpaceCoordinateOut( uint2 coordOut, float2 FlexCRTSize )
{
	// I believe these are equivelent. 
	//return float4((coordOut.xy*float2(2,-2)+float2(-2.0*FlexCRTSize.x*0.5+1.5,FlexCRTSize.y-1.5))/FlexCRTSize, 0.5, 1 );
	return float4( coordOut.xy*float2(1,-1)+float2(-FlexCRTSize.x/2+.5,FlexCRTSize.y/2-.5), 0, FlexCRTSize.x/2 );
}

#define MINIRV32_IMPLEMENTATION
#define MINIRV32WARN( x )
#define MINIRV32_POSTEXEC( pc, ir, trap )
// TODO WRITE ME
#define MINIRV32_HANDLE_MEM_STORE_CONTROL( addy, rs2 )
#define MINIRV32_OTHERCSR_WRITE( csrno, writeval )
#define MINIRV32_OTHERCSR_READ( csrno, rval ) rval = 0;
#define MINIRV32_STATE_DEFINTION MiniRV32IMAState state,
#define MINIRV32_HANDLE_MEM_LOAD_CONTROL( rsval, rval ) rval = 0;

#define MINIRV32_CUSTOM_INTERNALS
#define CSR( x ) state.x
#define SETCSR( x, val ) { state.x = val; }
#define REG( x ) state.regs[x]
#define REGSET( x, val ) { state.regs[x] = val; }

#define uint32_t uint
#define int32_t  int

#define MAXICOUNT    1024
#define MAX_FCNT     112
#define CACHE_BLOCKS 128
#define CACHE_N_WAY  2

#define INT32_MIN -2147483648
#define AS_SIGNED(val) (asint(val))
#define AS_UNSIGNED(val) (asuint(val))

#define MainSystemAccess( blockno ) _MainSystemMemory.Load( int3( blockno % SYSTEX_SIZE_X, blockno / SYSTEX_SIZE_X, 0 ) )
#define MINIRV32_STEPPROTO MINIRV32_DECORATE int32_t MiniRV32IMAStep( MINIRV32_STATE_DEFINTION uint32_t elapsedUs )

#define count MAXICOUNT

#define uint4assign( x, y ) x = y

#include "gpucache.h"

#include "mini-rv32ima.h"


#endif
