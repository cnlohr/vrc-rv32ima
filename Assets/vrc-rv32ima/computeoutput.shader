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
			//Blend One Zero

			CGPROGRAM
			
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			
			#pragma target 5.0
			
			
			#include "vrc-rv32ima.cginc"

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

			#include "mini-rv32ima.h"

			// Max # of instructions per runlet.
			#define MAXICOUNT 1024

			[maxvertexcount(128)]
			[instance(1)]
			void geo( point v2g input[1], inout PointStream<g2f> stream,
				uint instanceID : SV_GSInstanceID, uint geoPrimID : SV_PrimitiveID )
			{
				int batchID = input[0].batchID; // Should always be 0?
				
				cachesetsaddy = (uint[CACHE_BLOCKS])0;
				cachesetsdata = (uint4[CACHE_BLOCKS])0;
				g2f o;
				pixelOutputID = 0;
				uint Levels_ignored;

				uint elapsedUs = 1;
				MiniRV32IMAState state = (MiniRV32IMAState)0;
				uint s = MiniRV32IMAStep( state, elapsedUs );

				uint2 coordOut = uint2( 0, 0 );
				o.vertex = ClipSpaceCoordinateOut( coordOut, float2(128,2) );
				o.color = uint4(9, 8, 7, 6);
				stream.Append(o);
				
				coordOut = uint2( 0, 1 );
				o.vertex = ClipSpaceCoordinateOut( coordOut, float2(128,2) );
				o.color = uint4(5, 6, 7, 0xff);
				stream.Append(o);
#if 0
				int i;
				[loop]
				for( i = 0; i < MAX_FCNT; i++ )
				{
					uint a = emitblocks[i];

					//EmitGeo( a, cachesetsdata[i] );
					uint2 coordOut = uint2( pixelOutputID, 0 );
					o.vertex = ClipSpaceCoordinateOut( coordOut, float2(128,2) );
					o.color = uint4(a, 1, 0, 1);
					stream.Append(o);

					int j = 0;
					uint idx = (a%(CACHE_BLOCKS/CACHE_N_WAY))*CACHE_N_WAY;
					for( j = 0; j < CACHE_N_WAY; j++ )
					{
						if( cachesetsaddy[j+idx] == a )
						{
							coordOut = uint2( pixelOutputID++, 1 );
							o.vertex = ClipSpaceCoordinateOut( coordOut, float2(128,2) );
							o.color = cachesetsdata[j+idx];
							stream.Append(o);
							break;
						}
					}
				}
#endif
			}

			uint4 frag( g2f IN ) : SV_Target
			{
				return IN.color;
			}

			ENDCG
		}
    }
}
