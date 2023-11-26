Shader "rv32ima/loadimage"
{
    Properties
    {
		_MainTex( "Main Texture (Dummy)", 2D ) = "black" { }
		_LinuxImage( "Linux Image", 2D ) = "black" { }
		_DTBImage( "DTB Image", 2D ) = "black" { }

		_SystemMemorySize( "System Memory Size", Vector ) = ( 0, 0, 0, 0)
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

			texture2D <float> _LinuxImage;
			texture2D <float> _DTBImage;

			uint Read4Bytes( texture2D< float > tex, uint2 bc )
			{
				return ( ((uint)(tex[ bc + uint2(0,0) ]*255.5)) ) |
				       ( ((uint)(tex[ bc + uint2(1,0) ]*255.5)) << 8 ) |
					   ( ((uint)(tex[ bc + uint2(2,0) ]*255.5)) << 16 ) |
					   ( ((uint)(tex[ bc + uint2(3,0) ]*255.5)) << 24 );
			}

			uint4 Read16Bytes( texture2D< float > tex, uint2 bc )
			{
				return uint4(
					Read4Bytes( tex, bc + uint2( 0, 0 ) ),
					Read4Bytes( tex, bc + uint2( 4, 0 ) ),
					Read4Bytes( tex, bc + uint2( 8, 0 ) ),
					Read4Bytes( tex, bc + uint2( 12, 0 ) ) );
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

				uint3 LinuxImageSize; _LinuxImage.GetDimensions( 0, LinuxImageSize.x, LinuxImageSize.y, LinuxImageSize.z );
				uint LinuxImageBytes = (LinuxImageSize.x * LinuxImageSize.y);
				uint LinuxImageWidthBytes = LinuxImageSize.x;
				uint LinuxImageOHeight = ( LinuxImageBytes + TargetWidthBytes - 1 ) / TargetWidthBytes;

				uint3 DTBImageSize; _DTBImage.GetDimensions( 0, DTBImageSize.x, DTBImageSize.y, DTBImageSize.z );
				uint DTBImageBytes = (DTBImageSize.x * DTBImageSize.y);
				uint DTBImageWidthBytes = DTBImageSize.x;
				uint DTBImageOHeight = ( DTBImageBytes + TargetWidthBytes - 1 ) / TargetWidthBytes;

				// Load System Image
				if( coord.y < LinuxImageOHeight )
				{
					uint4 ret = 0;
					uint BaseMemoryAddressOfThisPixel = ( coord.y * _SystemMemorySize.x + coord.x ) * 4 * 4;
					uint2 syscoord = uint2( BaseMemoryAddressOfThisPixel % LinuxImageWidthBytes, BaseMemoryAddressOfThisPixel / LinuxImageWidthBytes );
					syscoord.y = LinuxImageSize.y - syscoord.y - 1;
					//return _LinuxImage[ uint2( coord.x, LinuxImageSize.y - coord.y - 1) ];
					return Read16Bytes( _LinuxImage, syscoord );
				}
				
				// Load the DTB + System Core
				uint topbase = _SystemMemorySize.y - 1 - DTBImageOHeight;
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
						uint dtb_address = 0x80000000 + TargetWidthBytes * topbase;
	
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
								0x00000000, // x10 (hart ID)!!
								dtb_address // x11 (DTB Pointer)
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
					else
					{
						// DTB Load
						uint4 ret = 0;
						uint BaseMemoryAddressOfThisPixel = ( ( coord.y - topbase ) * _SystemMemorySize.x + coord.x ) * 4 * 4;
						uint2 syscoord = uint2( BaseMemoryAddressOfThisPixel % DTBImageWidthBytes, BaseMemoryAddressOfThisPixel / DTBImageWidthBytes );
						syscoord.y = DTBImageSize.y - syscoord.y - 1;
						return Read16Bytes( _DTBImage, syscoord );
					}
				}
				
				return 0x00000000;
			}

			ENDCG
		}
    }
}
