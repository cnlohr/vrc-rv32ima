Shader "rv32ima/compute"
{
	Properties
	{
		_MainSystemMemory( "Main System Memory", 2D ) = "black" { }
		[ToggleUI] _SingleStep( "Single Step Enable", float ) = 0.0
		[ToggleUI] _SingleStepGo( "Single Step Go", float ) = 0.0
		_ElapsedTime( "Elapsed Time", float ) = .0001
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
			#pragma fragment frag
			#pragma target 5.0

			struct appdata
			{
                float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex	: SV_POSITION;
				uint batchID	: TEXCOORD2;
			};
			
			v2f vert(appdata IN)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(IN.vertex);
				return o;
			}
			
			
			float4 frag (v2f i) : SV_Target
            {
				return 0;
			}
			
			ENDCG
		}
		
		Pass
		{
			ZTest Always 
			//Blend One Zero

			CGPROGRAM
			
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			#pragma exclude_renderers d3d11_9x
			#pragma exclude_renderers d3d9	 // Just tried adding these because of a bgolus post to test,has no impact.
			#pragma target 5.0

			#pragma skip_optimizations d3d11
			//#pragma enable_d3d11_debug_symbols

			uint _SingleStepGo;
			uint _SingleStep;
			float _ElapsedTime;

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
				uint batchID	: TEXCOORD2;
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
			#if UNITY_SINGLE_PASS_STEREO
				return;
			#else
			
				int batchID = input[0].batchID; // Should always be 0?

				g2f o;
				uint i;
				cache_usage = 0;
				uint pixelOutputID = 0;
				uint elapsedUs = _ElapsedTime * 1000000;

				// Load state in from main ram.
				uint4 v;
				{
					for( i = 0; i < 13; i++ )
					{
						uint4 v = _MainSystemMemory.Load( uint3( i, SYSTEX_SIZE_Y-1, 0 ) );
						state[i*4+0] = v.x;
						state[i*4+1] = v.y;
						state[i*4+2] = v.z;
						state[i*4+3] = v.w;
					}
				}
				
				state[charout] = 0;

				bool nogo = false;
				
				if( _SingleStep )
				{
					if( state[stepstatus] == 0 && _SingleStepGo )
					{
						state[stepstatus] = 1;
					}
					else
					{
						nogo = true;
						if( !_SingleStepGo )
							state[stepstatus] = 0;
					}
					count = 1;
				}
				else
				{
					count = MAXICOUNT;
				}

				if( !nogo )
				{
					uint ret = MiniRV32IMAStep( elapsedUs );
					// 0 means keep going if possible
					// 1 means the processor needs to wait more time (waiting in timer interrupt) 
					//	TODO: We can take advantage of this and just update the timer registers as part of this pass.
					switch( ret )
					{
					case 0: // Normal operation, played through.
						break;
					case 1: // Waiting for timer interrupt.
					{
						uint cl = CSR( cyclel );
						cl+=0x1000; 
						if( cl < CSR( cyclel ) )
							SETCSR( cycleh, CSR( cycleh ) + 1 );
						SETCSR( cyclel, cl );
						break;
					}
					default:
						break;
					}
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

				{
					uint4 statealias[13];
					for( i = 0; i < 13; i++ )
					{
						statealias[i] = uint4( state[i*4+0], state[i*4+1], state[i*4+2], state[i*4+3] );

						uint2 coordOut = uint2( 64-13+i, 0 );
						o.vertex = ClipSpaceCoordinateOut( coordOut, float2(64,2) );
						o.color = uint4((MINI_RV32_RAM_SIZE)/16+1+i, 0, 0, 0);
						stream.Append(o);
						coordOut = uint2( 64-13+i, 1 );
						o.vertex = ClipSpaceCoordinateOut( coordOut, float2(64,2) );
						o.color = statealias[i];
						stream.Append(o);
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
