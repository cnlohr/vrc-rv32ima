Shader "rv32ima/TerminalShow"
{
	Properties
	{
		_ReadFromTerminal ("Terminal", 2D) = "white" {}
		[Toggle(_ShowHex)] _ShowHex ("Show Hex", float) = 0.0
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

			#pragma multi_compile_local _ _ShowHex
			#include "UnityCG.cginc"

			#include "/Packages/com.llealloo.audiolink/Runtime/Shaders/SmoothPixelFont.cginc"

			Texture2D<uint4> _ReadFromTerminal;
			float4 _ReadFromTerminal_TexelSize;
			float4 _SystemMemory_ST;

			float PrintHex( uint val, float2 uv )
			{
				uv.x = 1.0 - uv.x;
				uv *= float2( 8, 7 );
				int charno = uv.x/4;
				int row = uv.y/7;
				uint dig = (val >> (4-charno*4))&0xf;
				return PrintChar( (dig<10)?(dig+48):(dig+87), float2( charno*4-uv.x+4, uv.y-row*7 ), 2.0/(length( ddx( uv ) ) + length( ddy( uv ) )), 0.0);
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
				float2 uv = i.uv;
				uint2 termsize = _ReadFromTerminal_TexelSize.zw - uint2( 0, 1 );
				uv *= termsize;
				uint2 coord = uint2( uv.x, termsize.y-uv.y );
				uv.x = frac( uv );
				float4 color = 0;

				uv.x = 1.0 - uv.x;
				color = PrintChar( _ReadFromTerminal[coord], uv * float2( 4.0, 8.0 ), 2.0/(length( ddx( uv ) ) + length( ddy( uv ) )), 0.0);
#ifdef _ShowHex
				float phv = PrintHex( _ReadFromTerminal[coord], uv ).x;
				color = color * float4( 1.0-phv*2.0, 1.0, 1.0, 1.0 ) + float4( phv * 0.5, 0, 0, 0);
#endif
				UNITY_APPLY_FOG(i.fogCoord, color);
				return color;
			}
			ENDCG
		}
	}
}
