Shader "rv32ima/systemmemory"
{
    Properties
    {
		_ComputeBuffer( "Compute Buffer", 2D ) = "black" { }
		_SystemMemorySize( "System Memory Size", Vector ) = ( 0, 0, 0, 0)
		_ProcessorCount( "Processor Count", int ) = 1
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
			float4 _ComputeBuffer_TexelSize;

			struct appdata
			{
				float4 vertex	: SV_POSITION;
				uint	vertexID	: SV_VertexID;
			};

			struct v2g
			{
				float4 vertex	: SV_POSITION;
				uint batchID		: TEXCOORD2;
			};

			struct g2f
			{
				float4 vertex	: SV_POSITION;
				float pointSize : PSIZE;
				uint4  color	: TEXCOORD0;
			};

			v2g vert(appdata IN)
			{
				v2g OUT;
				OUT.batchID = IN.vertexID;
				OUT.vertex = 0;
				return OUT;
			}

			[maxvertexcount(COMPUTE_OUT_X)]
			[instance(32)]
			void geo( triangle v2g input[3], inout PointStream<g2f> stream,
				uint instanceID : SV_GSInstanceID, uint geoPrimID : SV_PrimitiveID )
			{
				// Just FYI there are two geoPrimID coming in here with graphics.blit.
				int batchID = input[0].batchID;
				//if( geoPrimID > 0 || instanceID > 0 ) return;

				if( instanceID >= _ProcessorCount ) return;

				g2f o;
				for( int i = 0; i < COMPUTE_OUT_X; i++ )
				{
#if UNITY_UV_STARTS_AT_TOP
					uint4 data = _ComputeBuffer[uint2(i,_ComputeBuffer_TexelSize.z - 1 - (0+instanceID*2))];
					uint4 addr = _ComputeBuffer[uint2(i,_ComputeBuffer_TexelSize.z - 1 - (1+instanceID*2))]; // Must be superword aligned.
#else
					uint4 data = _ComputeBuffer[uint2(i,0+instanceID*2)];
					uint4 addr = _ComputeBuffer[uint2(i,1+instanceID*2)]; // Must be superword aligned.
#endif
					if( addr.x < 1 ) continue;
					uint superword = addr.x - 1;
					uint2 outsize = _SystemMemorySize;
#if UNITY_UV_STARTS_AT_TOP
					uint2 coordOut = uint2( superword % outsize.x, superword / outsize.x );
#else
					uint2 coordOut = uint2( superword % outsize.x, outsize.x - 1 - superword / outsize.x );
#endif

					//coordOut = uint2( i, i );
					o.vertex = ClipSpaceCoordinateOut( coordOut, _SystemMemorySize.xy );
					o.color = data;
					o.pointSize = 1;
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
