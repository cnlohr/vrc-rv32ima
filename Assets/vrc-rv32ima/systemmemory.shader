Shader "rv32ima/systemmemory"
{
    Properties
    {
		_ComputeBuffer( "Compute Buffer", 2D ) = "black" { }
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

			texture2D <float4> _ComputeBuffer;
			
			#define FlexCRTSize float2(128,2)

			float4 FlexCRTCoordinateOut( uint2 coordOut )
			{
				return float4((coordOut.xy*2-FlexCRTSize+1)/FlexCRTSize, 0.5, 1 );
			}

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
				float4 color		: TEXCOORD0;				
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
				int batchID = input[0].batchID;
				g2f o;
				for( int i = 0; i < 128; i++ )
				{
					uint PixelID = i;
					uint2 coordOut = uint2( i, 0 );
					o.vertex = FlexCRTCoordinateOut( coordOut );
					o.color = uint4( 0xffffffff, 0x80000000, 0x80000000, 0x80000000 );
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
