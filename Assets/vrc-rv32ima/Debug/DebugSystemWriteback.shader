﻿Shader "Unlit/DebugSystemWriteback"
{
	Properties
	{
		_ComputeOut ("Compute Out", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Pass
		{			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fog

			#pragma target 5.0

			#include "UnityCG.cginc"

			//#include "/Packages/com.llealloo.audiolink/Runtime/Shaders/SmoothPixelFont.cginc"
			#include "/Assets/MSDFShaderPrintf/MSDFShaderPrintf.cginc"
			
			Texture2D<uint4> _ComputeOut;
			float4 _ComputeOut_TexSize;
			float4 _ComputeOut_ST;

			float4 PrintHexHoriz( uint4 val, float2 uv, float4 grad )
			{
				uv = frac( uv );
				uv *= float2( 36, 1 );
				uint charno = uv.x;
				int row = uv.y;
				uv.y = 1.0 - uv.y;
				uv.x = 1.0 - uv.x;
				uint dig = (val[uint(charno/9)] >> (28-(charno%9)*4))&0xf;
				if( charno%9 >= 8 ) dig = -55;
				//return PrintChar( (dig<10)?(dig+48):(dig+87), float2( charno*4-uv.x+4, uv.y-row*7 ), 2.0/(length( ddx( uv ) ) + length( ddy( uv ) )), 0.0);
				return MSDFPrintChar((dig<10)?(dig+48):(dig+87), float2( charno*4-uv.x+4, uv.y-row*7 ), grad).xxxy;
			}

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
				int w, h, d;
				_ComputeOut.GetDimensions( 0, w, h, d );
				float2 tuv = i.uv * float2( h, w );
				uint4 val = _ComputeOut.Load( uint3( w - uint( tuv.y ) - 1, uint( tuv.x ), 0 ) );
				float4 grad = float4( ddx(tuv), ddy(tuv) );
				float4 col = PrintHexHoriz( val, tuv, grad );
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
