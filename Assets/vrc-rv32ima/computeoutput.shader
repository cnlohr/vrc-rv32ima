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
			#pragma exclude_renderers d3d11_9x
            #pragma exclude_renderers d3d9     // Just tried adding these because of a bgolus post to test,has no impact.
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
				#ifdef UNITY_SINGLE_PASS_STEREO
				return;
				#endif
				int batchID = input[0].batchID; // Should always be 0?

				g2f o;
				uint i;
				cache_usage = 0;
				uint elapsedUs = 1;

				// Load state in from main ram.
				uint4 v;
				{
					for( i = 0; i < 12; i++ )
					{
						uint4 v = _MainSystemMemory.Load( uint3( i, SYSTEX_SIZE_Y-1, 0 ) );
						state[i*4+0] = v.x;
						state[i*4+1] = v.y;
						state[i*4+2] = v.z;
						state[i*4+3] = v.w;
					}
				}

				state[pcreg] = 0x80000000;

				uint s = MiniRV32IMAStep( elapsedUs );

				uint pixelOutputID = 0;

				for( i = 0; i < 12; i++ )
				{

					uint2 coordOut = uint2( pixelOutputID, 0 );
					o.vertex = ClipSpaceCoordinateOut( coordOut, float2(64,2) );
					o.color = uint4((MINI_RV32_RAM_SIZE)/16+1+i, 0, 0, 0);
					stream.Append(o);
					coordOut = uint2( pixelOutputID++, 1 );
					o.vertex = ClipSpaceCoordinateOut( coordOut, float2(64,2) );
					o.color = uint4( state[i*4+0], state[i*4+1], state[i*4+2], state[i*4+3] );;
					stream.Append(o);
				}
				
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
						o.color = cachesetsdata[i];
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
