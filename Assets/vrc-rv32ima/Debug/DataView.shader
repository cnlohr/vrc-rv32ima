Shader "Unlit/DataView"
{
    Properties
    {
        _MainSystemMemory ("Texture", 2D) = "white" {}
		[Toggle(_DoOverlay)] _DoOverlay( "Do Overlay", float ) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
			#pragma multi_compile _ _DoOverlay
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            Texture2D< uint4 > _MainSystemMemory;
            float4 _MainSystemMemory_ST;
            float4 _MainSystemMemory_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainSystemMemory);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
			
			float recoord( uint pcreg, float2 thisCoord )
			{
				uint pcv = _MainSystemMemory[uint2( pcreg/4, _MainSystemMemory_TexelSize.w - 1 )][pcreg%4] - 0x80000000;
				pcv /= 16;
				thisCoord += 0.25;
				float2 dpos = thisCoord - float2( pcv % _MainSystemMemory_TexelSize.z, pcv / _MainSystemMemory_TexelSize.w );
				float pcdist = length( dpos );
				float xclamp = max( 2.0-abs( dpos.x - dpos.y ), 2.0-abs( dpos.x + dpos.y ) );
				return min( saturate( 10.0 - abs( 11.0 - pcdist ) ), saturate(xclamp) );
			}

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = _MainSystemMemory[i.uv*_MainSystemMemory_TexelSize.zw] / (float)(0xffffffff);
				float2 thisCoord = i.uv * _MainSystemMemory_TexelSize.zw;
				
				#if _DoOverlay
					#define pcreg 32
					col = lerp( col, float4( 1.0, 1.0, 0.0, 0.0 ), recoord( 10, thisCoord ) );
					col = lerp( col, float4( 1.0, 1.0, 0.0, 0.0 ), recoord( 11, thisCoord ) );
					col = lerp( col, float4( 1.0, 1.0, 0.0, 0.0 ), recoord( 12, thisCoord ) );
					col = lerp( col, float4( 1.0, 1.0, 0.0, 0.0 ), recoord( 13, thisCoord ) );

					col = lerp( col, float4( 1.0, 0.0, 0.0, 0.0 ), recoord( 32, thisCoord ) );
					col = lerp( col, float4( 0.0, 0.0, 1.0, 0.0 ), recoord(  2, thisCoord ) );
					col = lerp( col, float4( 0.0, 1.0, 1.0, 0.0 ), recoord(  4, thisCoord ) );
				#endif
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
