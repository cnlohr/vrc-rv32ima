Shader "rv32ima/loadimage"
{
    Properties
    {
		_SystemImage( "System Image", 2D ) = "black" { }
		_DTBImage( "DTB Image", 2D ) = "black" { }
    }
    SubShader
    {
        Tags { }

		Pass
		{
			ZTest Always 
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma target 5.0
			
			#include "unitycg.cginc"

			texture2D <float> _SystemImage;
			texture2D <float> _DTBImage;
			float4 _SystemImage_TexelSize;
			float4 _DTBImage_TexelSize;

			struct appdata
			{
				float4  vertex      : POSITION;
				uint	vertexID	: SV_VertexID;
			};
			
			struct v2f
			{
				float4 vertex		: SV_POSITION;
				float2 screenPos    : TEXCOORD0;
				uint batchID		: TEXCOORD2;
			};
			
			v2f vert(appdata IN)
			{
				v2f OUT;
				OUT.batchID = IN.vertexID;
				OUT.vertex = UnityObjectToClipPos( IN.vertex );
				OUT.screenPos = ( IN.vertex );
				return OUT;
			}

			float4 frag( v2f IN ) : SV_Target
			{
				uint2 coord = IN.vertex;
				
				// The system image is loaded into the beginning of the texture.
				// The 
				
				return float4( coord&1,0,1 );
			}

			ENDCG
		}
    }
}
