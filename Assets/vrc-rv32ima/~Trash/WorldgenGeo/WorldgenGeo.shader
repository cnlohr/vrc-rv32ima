// Assuming 512 input primitives, outputs 524,288 tris.
// 1024 (32x32) tris per invocation.

Shader "ReferencePointToGeometryShader"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		Cull Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#pragma geometry geo
			#pragma multi_compile_fog
			#pragma target 5.0
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID //SPS-I
			};

			struct v2g
			{
				UNITY_VERTEX_OUTPUT_STEREO //SPS-I
			};

			struct g2f
			{
				float4 vertex : SV_POSITION;
				UNITY_VERTEX_OUTPUT_STEREO //SPS-I
				float4 uvab : UVAB;
			};

			v2g vert(appdata v, uint vid : SV_VertexID /* Always 0 for points */ )
			{
				// For some reason vid and iid can't be trusted here.
				// We just have to trust SV_PrimitiveID in the next step.
				v2g o;
				UNITY_SETUP_INSTANCE_ID(v); //SPS-I
				UNITY_INITIALIZE_OUTPUT(v2g, o); //SPS-I
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); //SPS-I
				return o;
			}
			
			[maxvertexcount(96)]
			
			[instance(32)]
			void geo( point v2g input[1], inout TriangleStream<g2f> triStream,
				uint instanceID : SV_GSInstanceID, uint geoPrimID : SV_PrimitiveID /* Always 0 for points? */ )
			{
				float3 objectCenter = float3( geoPrimID/64, geoPrimID%64, instanceID );
				
				g2f p[3];

				int vtx;
				for( vtx = 0; vtx < 32; vtx++ )
				{
					p[0].vertex = mul( UNITY_MATRIX_VP, float4( objectCenter.xyz + float3( 0.0, 0.0, 0.0 ), 1.0 ) );
					p[1].vertex = mul( UNITY_MATRIX_VP, float4( objectCenter.xyz + float3( 0.0, 0.5, 0.0 ), 1.0 ) );
					p[2].vertex = mul( UNITY_MATRIX_VP, float4( objectCenter.xyz + float3( 0.5, 0.0, 0.0 ), 1.0 ) );

					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(p[0]); //SPS-I
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(p[1]); //SPS-I
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(p[2]); //SPS-I

					p[0].uvab = float4( 0.0, 0.0, 0.0, 1.0 );
					p[1].uvab = float4( 1.0, 0.0, 0.0, 1.0 );
					p[2].uvab = float4( 0.0, 1.0, 0.0, 1.0 );
					triStream.Append(p[0]);
					triStream.Append(p[1]);
					triStream.Append(p[2]);
					triStream.RestartStrip();
					objectCenter.x += 8;
				}
			}
			

			fixed4 frag (g2f i) : SV_Target
			{
			
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i); //SPS-I

				fixed4 col = i.uvab;
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
