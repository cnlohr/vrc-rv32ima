Shader "rv32ima/loadimage-download"
{
    Properties
    {
		_ImportTexture( "PNG Image", 2D ) = "black" { }
		_SystemMemorySize( "System Memory Size", Vector ) = ( 0, 0, 0, 0)
		[ToggleUI] _DoNotSRGBConvert( "Do not SRGB convert", float ) = 0.0
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
			#include "vrc-rv32ima.cginc"

			texture2D <float4> _ImportTexture;
			float _DoNotSRGBConvert;
			
			float4 ColorCorrect4( float4 value )
			{
				if( _DoNotSRGBConvert > 0.5 ) return value;
				return float4(
					LinearToGammaSpaceExact( value.x + 0.0001),
					LinearToGammaSpaceExact( value.y + 0.0001),
					LinearToGammaSpaceExact( value.z + 0.0001),
					value.w );
				return value;
			}
			
			
			uint4 Read4Bytes( texture2D< float4 > tex, uint2 bc )
			{
				return ColorCorrect4( tex.Load( int3( bc + uint2(0,0), 0 ) ) ) * 255.55;
			}

			uint4 Read16Bytes( texture2D< float4 > tex, uint2 bc )
			{
				uint4 im0 = Read4Bytes( tex, bc + uint2( 0, 0 ) );
				uint4 im1 = Read4Bytes( tex, bc + uint2( 1, 0 ) );
				uint4 im2 = Read4Bytes( tex, bc + uint2( 2, 0 ) );
				uint4 im3 = Read4Bytes( tex, bc + uint2( 3, 0 ) );
				uint4 binrep = uint4(
					(im0.a << 24) + (im0.b << 16) + (im0.g << 8) + (im0.r << 0),
					(im1.a << 24) + (im1.b << 16) + (im1.g << 8) + (im1.r << 0),
					(im2.a << 24) + (im2.b << 16) + (im2.g << 8) + (im2.r << 0),
					(im3.a << 24) + (im3.b << 16) + (im3.g << 8) + (im3.r << 0)
				);
				return binrep;
			}

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

			uint4 frag( v2f IN ) : SV_Target
			{
				uint2 coord = IN.vertex;
				
				// The system image is loaded into the beginning of the texture.
				
				// Input source textures are always 1kB wide.

				uint TargetWidthBytes = _SystemMemorySize.x*4*4;

				uint3 PNGImageSize; _ImportTexture.GetDimensions( 0, PNGImageSize.x, PNGImageSize.y, PNGImageSize.z );
				uint PNGImageBytes = (PNGImageSize.x * PNGImageSize.y) * 4;
				uint PNGImageWidthBytes = PNGImageSize.x * 4;
				uint PNGImageOHeight = ( PNGImageBytes + TargetWidthBytes - 1 ) / TargetWidthBytes;
				
				// Load System Image
				if( coord.y < PNGImageOHeight )
				{
					uint4 ret = 0;
					uint BaseMemoryAddressOfThisPixel = ( coord.y * _SystemMemorySize.x + coord.x ) * 4 * 4;
					uint2 syscoord = uint2( (BaseMemoryAddressOfThisPixel/4) % PNGImageWidthBytes, (BaseMemoryAddressOfThisPixel /4 ) / PNGImageWidthBytes );
					syscoord.y = PNGImageSize.y - syscoord.y - 1;
					//return _LinuxImage[ uint2( coord.x, LinuxImageSize.y - coord.y - 1) ];
					return Read16Bytes( _ImportTexture, syscoord );
				}
				

				// Load the DTB + System Core
				uint topbase = _SystemMemorySize.y - 1;
				if( coord.y >= topbase )
				{
					if( coord.y == (uint)_SystemMemorySize.y - 1 )
					{
						//CPU Core Info Area
						/*
							uint32_t regs[8*4];
							pc, mstatus, cyclel, cycleh
							timerl, timerh, timermatchl, timermatchh
							mscratch, mtvec, mie, mip
							mepc, mtval, mcause, extraflags
						*/
						uint lpc = 0x80000000;
						uint dtb_address = 0x00000000; // 0x80000000 + TargetWidthBytes * topbase; (Normally) (DTB not used here)
						
	
						// Each color is 4 regs.
						if( coord.x == 8 )
							return uint4(
								lpc,        // PC (Image offset)
								0x00000000, // mstatus
								0x00000000, // cyclel
								0x00000000  // cycleh
							);
						else if( coord.x == 2 )
							return uint4(
								0x00000000, // x8
								0x00000000, // x9
								0x00000000, // x10 (hart ID)!!    (A0)
								dtb_address // x11 (DTB Pointer, normally)  (A1)
							);
						else if( coord.x == 3 )
							return uint4(
								0x80000000 + _SystemMemorySize.x * ( _SystemMemorySize.y - 2 ) * 4 * 4, // x12 A2 - ENVCTRL
								0x11100000, // x13 A3 - HOSTDAT
								0x00000000, // x14
								dtb_address // x15
							);
						else if( coord.x == 11 )
							return uint4(
								0x00000000, // mepc
								0x00000000, // mtval
								0x00000000, // mcause
								0x00000003  // machine mode.
							);
						else
							return 0x00000000;

					}
					/*
					else
					{
						// DTB Load
						uint4 ret = 0;
						uint BaseMemoryAddressOfThisPixel = ( ( coord.y - topbase ) * _SystemMemorySize.x + coord.x ) * 4 * 4;
						uint2 syscoord = uint2( BaseMemoryAddressOfThisPixel % DTBImageWidthBytes, BaseMemoryAddressOfThisPixel / DTBImageWidthBytes );
						syscoord.y = DTBImageSize.y - syscoord.y - 1;
						return Read16Bytes( _DTBImage, syscoord );
					}*/
				}
				
				return 0x00000000;
			}

			ENDCG
		}
    }
}
