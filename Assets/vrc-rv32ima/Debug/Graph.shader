Shader "rv32ima/Graph"
{
	Properties
	{
		_Statistics ("Statistics", 2D) = "white" {}
		_Fields( "Fields", float ) = 5.0
		[Toggle(_Debug)] _Debug( "Debug", float ) = 0.0
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
			#include "../vrc-rv32ima.cginc"
			
			#pragma multi_compile_local _ _Debug
			Texture2D<uint4> _Statistics;
			float4 _Statistics_TexelSize;
			float _Fields;

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
				const float fTimeDelta = 0.1; // Update if graph period updated.
			
			#if _Debug
				float2 uv = i.uv;
				uint2 termsize = uint2( 5, 5 ); //_Statistics_TexelSize.zw - uint2( 0, 1 );
				uv *= termsize;
				uint2 coord = uint2( uv.x, termsize.y-uv.y );
				uv.x = frac( uv );
				float4 color = 0;

				float phv = PrintHex8( _Statistics[coord], uv ).x;
				color = phv;
				UNITY_APPLY_FOG(i.fogCoord, color);
				return color;
			#else
				float2 graphuv = i.uv * float2( 1.0, _Fields );
				uint field = floor( graphuv.y );
				
				
				const float range[6] = { 1200, 1000, 30000, 300000, 400000, 1020 };
				const float textshift[6] = { 8, 8, 8, 8, 8, 6 };
				const float textscale[6] = { 1, 1, 1, 1, 1, .01 };
				graphuv.y = frac( graphuv.y ) * 1.1 - 0.05;
				
				float cloc = graphuv.x * _Statistics_TexelSize.z ;
				uint2 rounddown = uint2( cloc, field );
				float fra = frac( cloc.x );
				uint4 cellP = _Statistics[rounddown - uint2(1,0)];
				uint4 cellL = _Statistics[rounddown];
				uint4 cellR = _Statistics[rounddown + uint2(1,0)];
				
				float frasmooth = smoothstep( 0.0, 1.0, fra );
				float4 cv = lerp( cellL, cellR, fra );
				
				
				float4 cvint;
				if( fra < 0.5 )
				{
					cvint = lerp( (int4)cellP, (int4)cellL, fra+0.5 );
				}
				else
				{
					cvint = lerp( (int4)cellL, (int4)cellR, fra-0.5 );
				}
				
			
				float fRange = range[field];
				float y = cv.y / fRange;
				y = saturate(y);
				float intenpos = abs( graphuv.y - y );
				float width = fRange * 2.0 / ( abs( (int)cvint.z ) + (fRange/50) );

				float inten = 1.0 - intenpos * width;
				float4 color = saturate( lerp( 0.1, 1.0, inten ) );
				
				if( graphuv.y > 1.0 || graphuv.y < 0.0 )
				{
					color = float4( 0.1, 0.1, 0.1, 1. );
				}
				if( graphuv.x < _Statistics_TexelSize.x * 2.0 )
				{
					color = float4( 0.1, 0.1, 0.1, 1. );
				}
				if( graphuv.x < 0.21 && graphuv.y > 0.5 )
				{
					float2 thischar = ( graphuv - float2( 0.01, 0.5 ) ) * float2( 40.0, 4.0 );
					
					if( thischar.y < 0.0 || thischar.y > 2.0 || thischar.x < 0.0 )
					{
						// Do nothing.
					}
					else if( thischar.y > 1.0 && thischar.y < 1.9 )
					{
						thischar.y -= 1.0;	
						uint charnum[6*8] = {
							__S, __l, __e, __e, __p, __s, 0, 0,
							__E, __x, __e, __c, __u, __t, __e, __s,
							__W, __r, __i, __t, __e, __s, 0, 0,
							__T, __i, __m, __e,   0, __l, 0, 0,
							__C, __y, __c, __l, __e, __s, 0, 0,
							__C, __P, __U,  0, __P, __e, __r, __c,
							};

						float pc = PrintChar( charnum[uint(thischar.x) + field * 8], float2( 4.0, 0.0 ) + frac( thischar ) * float2( -4.0, 7.0), 10.0, 0.0 );
							//, float PrintChar(uint charNum, float2 charUV, float2 softness, float offset)
						color = lerp( color, float4(1.0,1.0,1.0,1.0), pc );
					}
					else
					{
						int val = 0;
						int j;
						for( j = 0; j < 10; j++ )
							val += _Statistics[uint2( 2+j, rounddown.y )].y;
						float dig = floor( thischar.x );
						val *= textscale[field];
						float pc = PrintNumberOnLine(val, float2( 4.0, 0.0 ) + frac( thischar ) * float2( -4.0, 7.0), 10.0, dig, textshift[field], 5, false, 0.0 );
						color = lerp( color, float4(1.0,1.0,1.0,1.0), pc );
					}
				}
				
				return color;
			#endif
			}
			ENDCG
		}
	}
}
