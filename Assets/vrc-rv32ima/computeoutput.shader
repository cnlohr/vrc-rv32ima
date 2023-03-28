Shader "rv32ima/compute"
{
    Properties
    {
		_MainSystemMemory( "Main System Memory", 2D ) = "black" { }
		_SystemMemorySize( "System Memory Size", Vector ) = ( 0, 0, 0, 0)
    }
    SubShader
    {
        Tags { }

		Pass
		{
			ZTest Always 

			CGPROGRAM
			
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			
			#pragma target 5.0
			
			
			#include "vrc-rv32ima.cginc"

			texture2D <float4> _MainSystemMemory;

			struct appdata
			{
				uint	vertexID	: SV_VertexID;
			};

			struct v2g
			{
				//float4 vertex	: SV_POSITION;
				uint batchID    : TEXCOORD2;
			};
			
			struct g2f
			{
				float4 vertex : SV_POSITION;
				uint4 color   : TEXCOORD0;				
			};

			v2g vert(appdata IN)
			{
				v2g OUT;
				OUT.batchID = IN.vertexID;
				return OUT;
			}

			// Looks like we have to use <<64kB of local storage.
			// We have "4096 temp registers."
			static uint4 cachesetsdata[1024];
			static uint  cachesetsaddy[1024];
			static uint  storeblockcount;
			static uint  need_to_flush_runlet;
			

			// Always aligned-to-4-bytes.
			uint LoadMemInternalRB( uint ptr )
			{
				int i;
				uint blockno = ptr / 16;
				uint hash = blockno & 0x7f;
				uint4 block;
				uint ct = 0;
				for( i = hash; i += 128; i<1024 )
				{
					ct = cachesetsaddy[i];
					if( ct == 0 ) break;
					if( ct == ptr )
					{
						// Found block.
						block = cachesetsdata[i];
					}
				}
				if( ct == 0 )
				{
					// else, no block found. Read data.
					block = _MainSystemMemory[uint2(blockno%SYSTEX_WIDTH,blockno/SYSTEX_WIDTH)];
				}
				return block[(ptr&0xf)>>2];
			}


			// todo: review all this.
			void StoreMemInternalRB( uint ptr, uint val )
			{
				int i;
				uint blockno = ptr / 16;
				// ptr will be aligned.
				// perform a 4-byte store.
				uint hash = blockno & 0x7f;
				uint4 block;
				uint ct = 0;
				// Cache lines are 8-deep, by 16 bytes, with 128 possible cache addresses.
				for( i = hash; i += 128; i<1024 )
				{
					ct = cachesetsaddy[i];
					if( ct == 0 ) break;
					if( ct == ptr )
					{
						// Found block.
						cachesetsdata[i][(ptr&0xf)>>2] = val;
						return;
					}
				}
				// NOTE: It should be impossible for i to ever be or exceed 1024.
				if( i >= (1024-128) )
				{
					// We have filled a cache line.  We must cleanup without any other stores.
					need_to_flush_runlet = 1;
				}
				cachesetsaddy[i] = blockno;
				block = _MainSystemMemory[uint2(blockno%SYSTEX_WIDTH,blockno/SYSTEX_WIDTH)];
				block[(ptr&0xf)>>2] = val;
				cachesetsdata[i] = block;
				storeblockcount++;
				// Make sure there's enough room to flush processor state (16 writes)
				if( storeblockcount >= 112 ) need_to_flush_runlet = 1;
			}

			// NOTE: len does NOT control upper bits.
			uint LoadMemInternal( uint ptr, uint len )
			{
				uint remo = ptr & 3;
				if( remo )
				{
					if( len > 4 - remo )
					{
						// Must be split into two reads.
						uint ret0 = LoadMemInternalRB( ptr & (~3) );
						uint ret1 = LoadMemInternalRB( (ptr & (~3)) + 4 );
						return (ret0 >> (remo*8)) | (ret1<<((4-remo)*8)); // XXX TODO:TESTME!!!
					}
					else
					{
						// Can just be one.
						uint ret = LoadMemInternalRB( ptr & (~3) );
						return ret >> (remo*8);
					}
				}
				return LoadMemInternalRB( ptr );
			}
			
			void StoreMemInternal( uint ptr, uint val, uint len )
			{
				uint remo = ptr & 3;
				if( remo )
				{
					if( len > 4 - remo )
					{
						// Must be split into two writes.
						uint ret0 = LoadMemInternalRB( ptr & (~3) );
						uint ret1 = LoadMemInternalRB( (ptr & (~3)) + 4 );
						uint loaded = (ret0 >> (remo*8)) | (ret1<<((4-remo)*8));
						uint mask = ((1<<(len*8))-1;
						loaded = (loaded & (~mask)) | ( val & mask );
						// XXX TODO
					}
					else
					{
						// Can just be one call.
						uint ret = LoadMemInternalRB( ptr & (~3) );
						return ret >> (remo*8);
						// XXX TODO
					}
				}
				if( len != 4 )
				{
					uint lv = LoadMemInternalRB( ptr );
					// XXX TODO
				}
				else
				{
					StoreMemInternalRB( ptr, val );
				}
			}


			// This is for stuff like UART, etc.  You can also set exceptions from in here.
			#define MINIRV32_HANDLE_MEM_STORE_CONTROL( addy, rs2 ) { } // XXX TODO
			#define MINIRV32_HANDLE_MEM_LOAD_CONTROL( addy, outv ) { outv = 0; } // XXX TODO
			
			#define MINIRV32_OTHERCSR_WRITE( csrno, writeval ) { } // Maybe todo?
			#define MINIRV32_OTHERCSR_READ( csrno, outv ) { outv = 0; } // Maybe todo?

			#define uint32_t uint
			#define int32_t int
			#define MINIRV32_IMPLEMENTATION
			#define MINIRV32_STEPPROTO uint MiniRV32IMAStep( MiniRV32IMAState state, uint image, uint vProcAddress, uint elapsedUs, int count )
			#define MINIRV32WARN
			#define MINIRV32_DECORATE
			#define MINI_RV32_RAM_SIZE MEMORY_SIZE
			#define MINIRV32_RAM_IMAGE_OFFSET MEMORY_BASE

			#define MINIRV32_POSTEXEC( a, b, c ) ;

			#define MINIRV32_CUSTOM_MEMORY_BUS
			uint MINIRV32_LOAD4( uint ofs ) { return LoadMemInternal( ofs, 4 ); }
			void MINIRV32_STORE4( uint ofs, uint val ) { StoreMemInternal( ofs, val, 4 ); if( need_to_flush_runlet ) icount = MAXICOUNT; }
			uint MINIRV32_LOAD2( uint ofs ) { uint tword = LoadMemInternal( ofs, 2 ) & 0xffff; return tword; }
			uint MINIRV32_LOAD1( uint ofs ) { uint tword = LoadMemInternal( ofs, 1 ) & 0xff; return tword; }
			int MINIRV32_LOAD2_SIGNED( uint ofs ) { uint tword = LoadMemInternal( ofs, 2 ) & 0xffff; if( tword & 0x8000 ) tword |= 0xffff; return tword; }
			int MINIRV32_LOAD1_SIGNED( uint ofs ) { uint tword = LoadMemInternal( ofs, 1 ) & 0xff;   if( tword & 0x80 ) tword |= 0xff; return tword; }
			void MINIRV32_STORE2( uint ofs, uint val ) { StoreMemInternal( ofs, val, 2 ); if( need_to_flush_runlet ) icount = MAXICOUNT; }
			void MINIRV32_STORE1( uint ofs, uint val ) { StoreMemInternal( ofs, val, 1 ); if( need_to_flush_runlet ) icount = MAXICOUNT; }

			#define MINIRV32_CUSTOM_INTERNALS
			#define CSR( x ) state.x
			#define SETCSR( x, val ) { state.x = val; }
			#define REG( x ) state.regs[x]
			#define REGSET( x, val ) { state.regs[x] = val; }
			
			
			#define INT32_MIN -2147483648
			
			#define AS_SIGNED(val) (asint(val))
			#define AS_UNSIGNED(val) (asuint(val))

			// From pi_maker's VRC RVC Linux
			// https://github.com/PiMaker/rvc/blob/eb6e3447b2b54a07a0f90bb7c33612aeaf90e423/_Nix/rvc/src/emu.h#L255-L276
			#define CUSTOM_MULH \
				case 1: \
				{ \
				    /* FIXME: mulh-family instructions have to use double precision floating points internally atm... */ \
					/* umul/imul (https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/umul--sm4---asm-)       */ \
					/* do exist, but appear to be unusable?                                                           */ \
					precise double op1 = AS_SIGNED(rs1); \
					precise double op2 = AS_SIGNED(rs2); \
					rval = uint((op1 * op2) / 4294967296.0l); /* '/ 4294967296' == '>> 32' */ \
					break; \
				} \
				case 2: \
				{ \
					/* is the signed/unsigned stuff even correct? who knows... */ \
					precise double op1 = AS_SIGNED(rs1); \
					precise double op2 = AS_UNSIGNED(rs2); \
					rval = uint((op1 * op2) / 4294967296.0l); /* '/ 4294967296' == '>> 32' */ \
					break; \
				} \
				case 3: \
				{ \
					precise double op1 = AS_UNSIGNED(rs1); \
					precise double op2 = AS_UNSIGNED(rs2); \
					rval = uint((op1 * op2) / 4294967296.0l); /* '/ 4294967296' == '>> 32' */ \
					break; \
				}
	
			#include "mini-rv32ima.h"

			// Max # of instructions per runlet.
			#define MAXICOUNT 1024

			[maxvertexcount(128)]
			[instance(1)]
			void geo( point v2g input[1], inout PointStream<g2f> stream,
				uint instanceID : SV_GSInstanceID, uint geoPrimID : SV_PrimitiveID )
			{
				int batchID = input[0].batchID; // Should always be 0?
				g2f o;
				cachesetsdata[instanceID] = 5;
				cachesetsaddy[99] = 5;


				for( int i = 0; i < 128; i++ )
				{
					uint PixelID = i;
					uint2 coordOut = uint2( i, geoPrimID );
					o.vertex = ClipSpaceCoordinateOut( coordOut, float2(128,2) );
					o.color = geoPrimID?(0x83ff8000+i*16): (cachesetsdata[i]+cachesetsaddy[i]);
					stream.Append(o);
				}
			}

			uint4 frag( g2f IN ) : SV_Target
			{
				return IN.color;
			}

			ENDCG
		}
    }
}
