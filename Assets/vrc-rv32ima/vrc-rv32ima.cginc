#ifndef VRC_RV32IMA
#define VRC_RV32IMA



#define MAXICOUNT    1024
#define MAX_FCNT     48
#define CACHE_BLOCKS 128
#define CACHE_N_WAY  2

Texture2D<uint4> _MainSystemMemory;

#define SYSTEX_SIZE_X 1024
#define SYSTEX_SIZE_Y 1024
#define MINI_RV32_RAM_SIZE (SYSTEX_SIZE_X*SYSTEX_SIZE_Y*16 - SYSTEX_SIZE_X*16)

#define MEMORY_BASE 0x80000000
#define MEMORY_SIZE (MINI_RV32_RAM_SIZE)

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

#define MINIRV32_OTHERCSR_WRITE( csrno, writeval ) if( csrno == 0x139 ) { CSR(charout) = writeval; icount = MAXICOUNT; }
#define MINIRV32_OTHERCSR_READ( csrno, rval ) rval = 0;
#define MINIRV32_STATE_DEFINTION

#define MINIRV32_HANDLE_MEM_STORE_CONTROL( addy, rs2 )  if( addy == 0x10000000 ) { CSR(charout) = rs2; icount = MAXICOUNT; }
#define MINIRV32_HANDLE_MEM_LOAD_CONTROL( rsval, rval ) rval = (rsval == 0x10000005)?0x60:0x00;

#define MINIRV32_CUSTOM_INTERNALS
#define MINIRV32_CUSTOM_STATE

//5792: ret 


#define pcreg [8][0]
#define mstatus [8][1]
#define cyclel [8][2]
#define cycleh [8][3]
#define timerl [9][0]
#define timerh [9][1]
#define timermatchl [9][2]
#define timermatchh [9][3]
#define mscratch [10][0]
#define mtvec [10][1]
#define mie [10][2]
#define mip [10][3]
#define mepc [11][0]
#define mtval [11][1]
#define mcause [11][2]
#define extraflags [11][3]

#define stepstatus [12][0]
#define charout [12][1]
#define sleeps [12][2]
#define debug3 [12][3]

static uint4 state[52/4] = (uint4[52/4])0;

#define CSR( x ) state x
#define SETCSR( x, val ) { state x = val; }
#define REG( x ) state[(x)/4][(x)%4]
#define REGSET( x, val ) { state[(x)/4][(x)%4] = val; }

#define uint32_t uint
#define int32_t  int


#define INT32_MIN -2147483648
#define AS_SIGNED(val) (asint(val))
#define AS_UNSIGNED(val) (asuint(val))

#define MainSystemAccess( blockno ) _MainSystemMemory[uint2( (blockno) % SYSTEX_SIZE_X, (blockno) / SYSTEX_SIZE_X)]
#define MINIRV32_STEPPROTO MINIRV32_DECORATE int32_t MiniRV32IMAStep( MINIRV32_STATE_DEFINTION uint32_t elapsedUs )

static uint count;

#define uint4assign( x, y ) x = y


#endif
