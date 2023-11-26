Shader "rv32ima/compute"
{
    Properties
    {
		_MainSystemMemory( "Main System Memory", 2D ) = "black" { }
		_MaxICount( "Max I Count", float ) = 1024
    }
    SubShader
    {
        Tags { }

		Pass
		{
			ZTest Always 
			//Blend One Zero

			CGPROGRAM
			
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			
			#pragma target 5.0
			
			
			float _MaxICount;

			#include "vrc-rv32ima.cginc"			
			#include "gpucache.h"
			#include "mini-rv32ima.h"


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
				//XXX: TODO: Can we shrink this down and use Z to somehow indicate location, to reduce number of outputs required from geo?
				float4 vertex : SV_POSITION;
				uint4 color   : TEXCOORD0;				
			};

			v2g vert(appdata IN)
			{
				v2g OUT;
				OUT.batchID = IN.vertexID;
				return OUT;
			}

			[maxvertexcount(128)]
			[instance(1)]
			void geo( point v2g input[1], inout PointStream<g2f> stream,
				uint instanceID : SV_GSInstanceID, uint geoPrimID : SV_PrimitiveID )
			{
				int batchID = input[0].batchID; // Should always be 0?
				
				int i;
				for( i = 0; i < CACHE_BLOCKS; i++ )
				{
					cachesetsaddy[i] = 0;
					cachesetsdata[i] = 0;
				}

				g2f o;
				cache_usage = 0;
				pixelOutputID = 0;
				uint Levels_ignored;
				uint elapsedUs = 1;
				state = (uint[48])0;


				// Load state in from main ram.
				uint4 v;
				{
					uint4 statealias[12];
					for( i = 0; i < 12; i++ )
					{
						statealias[i] = _MainSystemMemory.Load( uint3( i, SYSTEX_SIZE_Y-1, 0 ) );
					}
					
					for( i = 0; i < 12; i++ )
					{
						v = statealias[i];
						state[i*4+0] = v.x;
						state[i*4+1] = v.y;
						state[i*4+2] = v.z;
						state[i*4+3] = v.w;
					}
				}
				
								
								state[pcreg] = 0x80000000;

				uint s = MiniRV32IMAStep( elapsedUs );
				
				
#if 1
				[unroll]
				for( i = 0; i < CACHE_BLOCKS; i++ )
				{
					uint a = cachesetsaddy[i];
					if( a > 0 )
					{
						uint2 coordOut = uint2( pixelOutputID, 0 );
						o.vertex = ClipSpaceCoordinateOut( coordOut, float2(64,2) );
						o.color = uint4(a, 0, 0, 0);
						stream.Append(o);
						coordOut = uint2( pixelOutputID++, 1 );
						o.vertex = ClipSpaceCoordinateOut( coordOut, float2(64,2) );
						o.color = uint4( cachesetsdata[i*4+0], cachesetsdata[i*4+1], cachesetsdata[i*4+2], cachesetsdata[i*4+3] );
						stream.Append(o);
					}
				}
				
#else
				for( i = 0; i < MAX_FCNT; i++ )
				{
					uint a = emitblocks[i];

					//EmitGeo( a, cachesetsdata[i] );
					uint2 coordOut = uint2( pixelOutputID, 0 );
					o.vertex = ClipSpaceCoordinateOut( coordOut, float2(64,2) );
					o.color = uint4(a, 0, 0, 0);
					stream.Append(o);

					int j = 0;
					uint idx = (a%(CACHE_BLOCKS/CACHE_N_WAY))*CACHE_N_WAY;
					for( j = 0; j < CACHE_N_WAY; j++ )
					{
						if( cachesetsaddy[j+idx] == a )
						{
							coordOut = uint2( pixelOutputID++, 1 );
							o.vertex = ClipSpaceCoordinateOut( coordOut, float2(64,2) );
							o.color = cachesetsdata[j+idx];
							stream.Append(o);
							break;
						}
					}
				}
#endif

				{
					uint4 statealias[12];
					for( i = 0; i < 12; i++ )
					{
						statealias[i] = uint4( state[i*4+0], state[i*4+1], state[i*4+2], state[i*4+3] );

						uint2 coordOut = uint2( pixelOutputID, 0 );
						o.vertex = ClipSpaceCoordinateOut( coordOut, float2(64,2) );
						o.color = uint4((MINI_RV32_RAM_SIZE)/16+1+i, 0, 0, 0);
						stream.Append(o);
						coordOut = uint2( pixelOutputID++, 1 );
						o.vertex = ClipSpaceCoordinateOut( coordOut, float2(64,2) );
						o.color = statealias[i];
						stream.Append(o);
					}
				}

/*
				while( pixelOutputID < 64 )
				{
					uint2 coordOut = uint2( pixelOutputID, 0 );
					o.vertex = ClipSpaceCoordinateOut( coordOut, float2(64,2) );
					o.color = uint4(0, 0, 0, 0);
					stream.Append(o);
					coordOut = uint2( pixelOutputID++, 1 );
					o.vertex = ClipSpaceCoordinateOut( coordOut, float2(64,2) );
					o.color = uint4(0xaaaaaaaa, pixelOutputID, 0xffffffff, 0xffffffff);
					stream.Append(o);
				}
*/

			}


			uint4 frag( g2f IN ) : SV_Target
			{
				return IN.color;
			}

			ENDCG
		}
    }
}
