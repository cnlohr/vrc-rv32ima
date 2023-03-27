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
					o.color = geoPrimID?(0x83ff8000+i*16):0xf1234567;
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
