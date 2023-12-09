Shader "Custom/TopBlockExamineX"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
		
		#include "..\AudioLink\Shaders\SmoothPixelFont.cginc"
		#include <UnityCG.cginc>
		
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        #pragma target 5.0


        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

		#ifndef glsl_mod
		#define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
		#endif

		uniform float4               _MainTex_TexelSize;

		//#ifdef SHADER_TARGET_SURFACE_ANALYSIS
		//#define AUDIOLINK_STANDARD_INDEXING
		//#endif

		// Mechanism to index into texture.
		//#ifdef AUDIOLINK_STANDARD_INDEXING
			sampler2D _MainTex;
			#define LData(xycoord) tex2Dlod(_MainTex, float4(uint2(xycoord) * _MainTex_TexelSize.xy, 0, 0))
		//#else
		//	uniform Texture2D<float4>   _MainTex;
		//	#define LData(xycoord) _MainTex[uint2(xycoord)]
		//#endif
		


        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float2 uv = IN.uv_MainTex;
			uv.y = 1. - uv.y;
            // Albedo comes from a texture tinted by color
			float4 c;


			//uv.x = 1. - uv.x;
			float2 tx = uv*float2(128,16*3);
			int2 cpos = floor(tx.xy);
			float am = 0;
			int2 cell = int2( cpos.x / 8, cpos.y );

			if( (cpos.x & 7) == 7 )
			{
				am = 0;
				c = float4( ((cell.y%3)==0), ((cell.y%3)==1), ((cell.y%3)==2), 1 );
			}
			else
			{
				cpos.x &= 7;
				int2 readpos = cell/int2(1,3);
				readpos.y = _MainTex_TexelSize.w - readpos.y - 1;
				float4 dat = LData(readpos);
			//	dat.x = LinearToGammaSpace( dat.x );
			//	dat.y = LinearToGammaSpace( dat.y );
			//	dat.z = LinearToGammaSpace( dat.z );
				float4 cd = dat*255.0;
				float value = ((cell.y%3)==0)?cd.x:(((cell.y%3)==1)?cd.y:cd.z);
				//value = readpos.y;
				am = PrintNumberOnLine( value, float2(4,8)-frac(tx)*float2(4,8), 10, cpos.x, 3, 3, 0, 0 );
				c = 0;
			}
			
			c += am.xxxx;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
			
        }
        ENDCG
    }
    FallBack "Diffuse"
}
