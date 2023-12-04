Shader "rv32ima/Statistics"
{
    Properties
    {
		_CompLast( "Compute Buffer", 2D ) = "black" { }
		_LastStat( "Last Stat", 2D ) = "black" { }
		[ToggleUI] _Reset( "Reset", float ) = 0.0
		[ToggleUI] _Advance( "Advance", float ) = 0.0
    }
    SubShader
    {
        Tags { }

		Pass
		{
			ZTest Always
			Blend One Zero

			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma target 5.0
			
			#include "vrc-rv32ima.cginc"

			texture2D <uint4> _CompLast;
			texture2D <uint4> _LastStat;
			float4 _LastStat_TexelSize;
			float _Reset, _Advance;

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
				OUT.screenPos = ( IN.vertex ) * _LastStat_TexelSize.zw;
				return OUT;
			}
			
			uint signExtend16Bit( uint x )
			{
				// Compute bit-wise sign 2's compliment expansion (automatic sign extension)
				return x | -( (int)( x & 0x8000 ) << 1 ); 
			}
			
			uint ExtendSign( uint val, uint newv, uint mask )
			{
				uint maskedval = (val & mask);
				uint rdiff = (newv - maskedval);
				rdiff &= mask;
				return val + rdiff;
			}

			uint4 frag( in v2f IN ) : SV_Target
			{
				if( _Reset > 0.5 ) return 0;
				uint2 tc = IN.vertex.xy;

				uint4 lastStat = _LastStat[IN.screenPos];
				
				if( tc.x > 0 )
				{
					if( _Advance > 0.5 )
					{
						uint4 lastStatPrev = _LastStat[IN.screenPos - uint2( 1, 0 )];
						
						if( tc.y == 5 )
						{
							lastStatPrev.y = 1000 * _LastStat[uint2( IN.screenPos.x - 1, 1 )].y / ( _LastStat[uint2( IN.screenPos.x - 1, 1 )].y + _LastStat[uint2( IN.screenPos.x - 1, 0 )].y ) ;
						}
						else
						{
							lastStatPrev.y = lastStatPrev.x - lastStat.x;
						}
						lastStatPrev.z = lastStatPrev.y - lastStat.y;
						return lastStatPrev;
					}
					else
					{
						return lastStat;
					}
				}
				
				
				uint4 regblock = _CompLast[uint2(63,1)];
				uint cpuinfo   = regblock.z;
				uint sleeps    = cpuinfo & 0xfff;
				uint cpuct     = ( cpuinfo >> 12 ) & 0xfff;
				uint writes    = ( cpuinfo >> 24 ) & 0xff;
				
				regblock = _CompLast[uint2(60,1)];
				uint timl = regblock.x;

				regblock = _CompLast[uint2(59,1)];
				uint cycl = regblock.z;
				
				switch( tc.y )
				{
				case 0: if( sleeps) lastStat.x = ExtendSign( lastStat.x, sleeps, 0xfff ); lastStat.z = sleeps; break;
				case 1: if( cpuct ) lastStat.x = ExtendSign( lastStat.x, cpuct, 0xfff ); lastStat.z = cpuct;   break;
				case 2: if( writes) lastStat.x += writes; lastStat.z = writes;  break;
				case 3: if(timl) lastStat.x = timl; break;
				case 4: if(cycl) lastStat.x = cycl; break;
				case 5: lastStat.x = 0; break; 
				}
				
				return lastStat;
			}

			ENDCG
		}
    }
}
