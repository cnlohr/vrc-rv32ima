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
			
			uint MINIRV32_LOAD4( uint ofs ) { } // XXX TODO!!!
			uint MINIRV32_STORE4( uint ofs, uint val ) { } // XXX TODO!!!

			// This is for stuff like UART, etc.  You can also set exceptions from in here.
			#define MINIRV32_HANDLE_MEM_STORE_CONTROL( addy, rs2 ) { } // XXX TODO
			#define MINIRV32_HANDLE_MEM_LOAD_CONTROL( addy, outv ) { } // XXX TODO
			
			#define MINIRV32_OTHERCSR_WRITE( csrno, writeval ) { } // Maybe todo?
			#define MINIRV32_OTHERCSR_READ( csrno, outv ) { } // Maybe todo?

			
			#define uint32_t uint
			#define int32_t int
			#define MINIRV32_IMPLEMENTATION
			#define MINIRV32_STEPPROTO uint MiniRV32IMAStep( MiniRV32IMAState state, uint image, uint vProcAddress, uint elapsedUs, uint count )
			#define MINIRV32WARN
			#define MINIRV32_DECORATE
			#define MINI_RV32_RAM_SIZE MEMORY_SIZE
			#define MINIRV32_RAM_IMAGE_OFFSET MEMORY_BASE

			#define MINIRV32_POSTEXEC

			#define MINIRV32_CUSTOM_MEMORY_BUS
			uint MINIRV32_LOAD2( uint ofs ) { uint tword = MINIRV32_LOAD4( ofs ) & 0xffff; return tword; }
			uint MINIRV32_LOAD1( uint ofs ) { uint tword = MINIRV32_LOAD4( ofs ) & 0xff; return tword; }
			int MINIRV32_LOAD2_SIGNED( uint ofs ) { uint tword = MINIRV32_LOAD4( ofs ) & 0xffff; if( tword & 0x8000 ) tword |= 0xffff; return tword; }
			int MINIRV32_LOAD1_SIGNED( uint ofs ) { uint tword = MINIRV32_LOAD4( ofs ) & 0xff;   if( tword & 0x80 ) tword |= 0xff; return tword; }
			uint MINIRV32_STORE2( uint ofs, uint val ) { uint tword = MINIRV32_LOAD4( ofs ); MINIRV32_STORE4( ofs, (tword & 0xffff0000) | (val & 0xffff) ); }
			uint MINIRV32_STORE1( uint ofs, uint val ) { uint tword = MINIRV32_LOAD4( ofs ); MINIRV32_STORE4( ofs, (tword & 0xffffff00) | (val & 0xff) ); }

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

			[maxvertexcount(128)]
			[instance(1)]
			void geo( point v2g input[1], inout PointStream<g2f> stream,
				uint instanceID : SV_GSInstanceID, uint geoPrimID : SV_PrimitiveID )
			{
				int batchID = input[0].batchID; // Should always be 0?
				g2f o;
				for( int i = 0; i < 128; i++ )
				{
					uint PixelID = i;
					uint2 coordOut = uint2( i, geoPrimID );
					o.vertex = ClipSpaceCoordinateOut( coordOut, float2(128,2) );
					o.color = geoPrimID?(0x83ff8000+i*16): 0x40000000;
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
