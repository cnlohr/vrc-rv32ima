Shader "rv32ima/systemmemory"
{
    Properties
    {
		_ComputeBuffer( "Compute Buffer", 2D ) = "black" { }
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

			texture2D <uint4> _ComputeBuffer;

			struct appdata
			{
				uint	vertexID	: SV_VertexID;
			};

			struct v2g
			{
				//float4 vertex	: SV_POSITION;
				uint batchID		: TEXCOORD2;
			};

			struct g2f
			{
				float4 vertex		: SV_POSITION;
				uint4  color		: TEXCOORD0;				
			};

			v2g vert(appdata IN)
			{
				v2g OUT;
				OUT.batchID = IN.vertexID;
				return OUT;
			}

			[maxvertexcount(64)]
			[instance(1)]
			void geo( point v2g input[1], inout PointStream<g2f> stream,
				uint instanceID : SV_GSInstanceID, uint geoPrimID : SV_PrimitiveID )
			{
				// Just FYI there are two geoPrimID coming in here with graphics.blit.
				int batchID = input[0].batchID;
				//if( geoPrimID > 0 || instanceID > 0 ) return;

				g2f o;
				for( int i = 0; i < 64; i++ )
				{
					uint4 data = _ComputeBuffer[uint2(i,1)];
					uint4 addr = _ComputeBuffer[uint2(i,0)]; // Must be superword aligned.
					
					if( addr.x < 1 ) return;
					uint superword = addr.x - 1;
					uint2 outsize = _SystemMemorySize;
					uint2 coordOut = uint2( superword % outsize.x, superword / outsize.x );

					//coordOut = uint2( i, i );
					o.vertex = ClipSpaceCoordinateOut( coordOut, _SystemMemorySize.xy );
					o.color = data;
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
