
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;
using VRC.SDK3.Image;
using VRC.SDK3.StringLoading;
using VRC.Udon.Common.Interfaces;


[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class rv32ima : UdonSharpBehaviour
{
	public RenderTexture computeBuffer;
	public RenderTexture systemMemory;
	public Material      computeMaterial;
	public Material      systemWriter;
	public Material      terminalShow;
	public Material      terminalInternal;
	public RenderTexture terminalInternal1;
	public RenderTexture terminalInternal2;

	public Material      loadImage;

	public Material       statistics;
	public RenderTexture  statisticsTexture;
	private RenderTexture statisticsBack;
	
	public bool imageIsDownloadable;

	private int frames;
	private int gameframes;
	public int iterations = 100;
	private System.DateTime last;
	public double timeCompression = 0.1;
	private double statAdvance = 0;
	private bool running = true;
	private bool step = false;

	private bool doneInitial = false;
	public VRCUrl stringUrl;	
	private VRCImageDownloader _imageDownloader;
	private IUdonEventReceiver _udonEventReceiver;

	private Color [] generalArray = new Color[1024];
	private Color [] playerArray = new Color[1024];
	private Color [] boneArray = new Color[1024];

	void Start()
	{
		Debug.Log( $"System Memory Size: {systemMemory.width}, {systemMemory.height}" );

		computeMaterial.SetVector( "_SystemMemorySize", new Vector4( systemMemory.width, systemMemory.height, 0, 0 ) );
		loadImage.SetVector( "_SystemMemorySize", new Vector4( systemMemory.width, systemMemory.height, 0, 0 ) );
		systemWriter.SetVector( "_SystemMemorySize", new Vector4( systemMemory.width, systemMemory.height, 0, 0 ) );

		terminalInternal.SetTexture( "_SystemMemory", systemMemory );
        statisticsBack = new RenderTexture(statisticsTexture.width, statisticsTexture.height, 1, RenderTextureFormat.ARGBInt );
        statisticsBack.Create();
		last = System.DateTime.Now;
		
		
		if( imageIsDownloadable )
			Redownload();
		else
			Restart();
	}
 
	void Update()
	{
		computeMaterial.SetFloat( "_SingleStep", 0.0f );
		computeMaterial.SetFloat( "_SingleStepGo", 0.0f );
		if( !running ) return;
		if( frames == 0 )
		{
			terminalInternal.SetFloat( "_Clear", 1.0f );
			terminalInternal.SetTexture( "_ReadFromTerminal", terminalInternal2 );
			VRCGraphics.Blit( null, terminalInternal1, terminalInternal, -1 ); 
			terminalInternal.SetTexture( "_ReadFromTerminal", terminalInternal1 );
			VRCGraphics.Blit( null, terminalInternal2, terminalInternal, -1 ); 
			terminalInternal.SetFloat( "_Clear", 0.0f );
		}

		if( iterations > 100 ) iterations = 100;
		int do_iterations = iterations;

		if( step )
		{
			computeMaterial.SetFloat( "_SingleStep", 1.0f );
			do_iterations = 1;
		}
		else
		{
			computeMaterial.SetFloat( "_SingleStep", 0.0f );
		}

		int i;
		System.DateTime now = System.DateTime.Now;
		System.TimeSpan diff = System.DateTime.Now - last;
		double elapsed = diff.TotalSeconds * timeCompression;
		statAdvance += elapsed;
		
		if( statAdvance > 0.1 )
		{
			if( statAdvance > 0.2 )
			{
				statAdvance = 0;
			}
			else
			{
				statAdvance -= 0.1;
			}
			statistics.SetFloat( "_Advance", 1.0f );
		}
		
		
		computeMaterial.SetFloat( "_ElapsedTime", (float)(elapsed/do_iterations) );
		statistics.SetTexture( "_CompLast", computeBuffer );

		// See vrc-rv32ima.h in the host.
		VRCPlayerApi [] players = new VRCPlayerApi[128];
		VRCPlayerApi.GetPlayers(players);
		int n = 0;
		Vector3 vScale3 = new Vector3( 65536.0f, 65536.0f, 65536.0f );
		Vector3 vScale4 = new Vector4( 65536.0f, 65536.0f, 65536.0f, 65536.0f );
		Color cEmpty = new Color( 0, 0, 0, 0 );
		int npc = VRCPlayerApi.GetPlayerCount() * 8;
		int nIdOfLocalPlayer = 0;
		foreach( VRCPlayerApi p in players )
		{
			if( n >= npc )
			{
				playerArray[n] = cEmpty;
			}
			else
			{
				if( p.isLocal ) nIdOfLocalPlayer = n / 8;
				string s = p.displayName;
				Vector3 place = Vector3.Scale( p.GetPosition(), vScale3 );
				Vector4 rotation = p.GetRotation() * vScale4;

				playerArray[0+n] = new Color( 
					1 | (p.isLocal ? 2 : 0 ) | ( p.isMaster ? 4 : 0 ) | (p.IsUserInVR() ? 8 : 0 ),
					0, 0, 0);

				s += "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000";
				playerArray[1+n] = new Color( place.x, place.y, place.z, 65536.0f );
				playerArray[2+n] = new Color( rotation.w, rotation.x, rotation.y, rotation.z );
				playerArray[3+n] = new Color( char.ConvertToUtf32(s, 0), char.ConvertToUtf32(s, 1), char.ConvertToUtf32(s, 2), char.ConvertToUtf32(s, 3) );
				playerArray[4+n] = new Color( char.ConvertToUtf32(s, 4), char.ConvertToUtf32(s, 5), char.ConvertToUtf32(s, 6), char.ConvertToUtf32(s, 7) );
				playerArray[5+n] = new Color( char.ConvertToUtf32(s, 8), char.ConvertToUtf32(s, 9), char.ConvertToUtf32(s, 10), char.ConvertToUtf32(s, 11) );
				playerArray[6+n] = new Color( char.ConvertToUtf32(s, 12), char.ConvertToUtf32(s, 13), char.ConvertToUtf32(s, 14), char.ConvertToUtf32(s, 15) );
				playerArray[7+n] = new Color( char.ConvertToUtf32(s, 16), char.ConvertToUtf32(s, 17), char.ConvertToUtf32(s, 18), char.ConvertToUtf32(s, 19) );
				
				Vector3 b;
				b = Vector3.Scale( p.GetBonePosition( HumanBodyBones.LeftFoot ), vScale3 );
				boneArray[0+n] = new Color( b.x, b.y, b.z, 0 );
				b = Vector3.Scale( p.GetBonePosition( HumanBodyBones.RightFoot ), vScale3 );
				boneArray[1+n] = new Color( b.x, b.y, b.z, 0 );
				b = Vector3.Scale( p.GetBonePosition( HumanBodyBones.Head ), vScale3 );
				boneArray[2+n] = new Color( b.x, b.y, b.z, 0 );
				b = Vector3.Scale( p.GetBonePosition( HumanBodyBones.Chest ), vScale3 );
				boneArray[3+n] = new Color( b.x, b.y, b.z, 0 );
				b = Vector3.Scale( p.GetBonePosition( HumanBodyBones.LeftHand ), vScale3 );
				boneArray[4+n] = new Color( b.x, b.y, b.z, 0 );
				b = Vector3.Scale( p.GetBonePosition( HumanBodyBones.RightHand ), vScale3 );
				boneArray[5+n] = new Color( b.x, b.y, b.z, 0 );
			}

			n+=8;
			if( n >= 1023 ) break;
		}
		
		VRCPlayerApi localPlayer = players[nIdOfLocalPlayer];
		
		generalArray[0] = new Color( gameframes%16777216, gameframes/16777216, VRCPlayerApi.GetPlayerCount(), nIdOfLocalPlayer );
		generalArray[1] = new Color( 0, 0, 0, 0 );
	
		generalArray[3] = new Color( 
			Mathf.Max(Input.GetAxisRaw("Oculus_CrossPlatform_PrimaryIndexTrigger") * 65536, Input.GetMouseButton(0) ? 65536 : 0), 
			Mathf.Max(Input.GetAxisRaw("Oculus_CrossPlatform_SecondaryIndexTrigger") * 65536, 0), 
			0, 0
			);

		int currentHandID;
		bool inVR = localPlayer.IsUserInVR();
		for( currentHandID = 0; currentHandID < (inVR?2:1); currentHandID++ )
		{
			VRCPlayerApi.TrackingDataType hand;
			float rotationangle = 41.0f;
			if( !inVR )
			{
				hand = VRCPlayerApi.TrackingDataType.Head;
				rotationangle = 0;
			}
			else if( currentHandID == 0 )
			{
				hand = VRCPlayerApi.TrackingDataType.LeftHand;
			}
			else
			{
				hand = VRCPlayerApi.TrackingDataType.RightHand;
			}
			VRCPlayerApi.TrackingData xformHand = localPlayer.GetTrackingData( hand );
			Vector3 b = Vector3.Scale( xformHand.position, vScale3 );
			generalArray[4+currentHandID*2] = new Color( b.x, b.y, b.z, 0 );
			b = Vector3.Scale( (xformHand.rotation * Quaternion.Euler(0.0f, rotationangle, 0.0f) ) * Vector3.forward, vScale3 );
			generalArray[5+currentHandID*2] = new Color( b.x, b.y, b.z, 0 );
		}

		{
			Vector3 b = Vector3.Scale( localPlayer.GetBonePosition( HumanBodyBones.LeftIndexDistal ), vScale3 );
			generalArray[8] = new Color( b.x, b.y, b.z, 0 );
			b = Vector3.Scale( localPlayer.GetBonePosition( HumanBodyBones.RightIndexDistal ), vScale3 );
			generalArray[9] = new Color( b.x, b.y, b.z, 0 );
			b = Vector3.Scale( localPlayer.GetBonePosition( HumanBodyBones.LeftIndexIntermediate ), vScale3 );
			generalArray[10] = new Color( b.x, b.y, b.z, 0 );
			b = Vector3.Scale( localPlayer.GetBonePosition( HumanBodyBones.RightIndexIntermediate ), vScale3 );
			generalArray[11] = new Color( b.x, b.y, b.z, 0 );
		}


		gameframes++;
		 
		computeMaterial.SetColorArray( "_GeneralArray", generalArray );
		computeMaterial.SetColorArray( "_PlayerArray", playerArray );
		computeMaterial.SetColorArray( "_BoneArray", boneArray );

		for( i = 0; i < do_iterations; i++ )
		{
			bool bIsOddFrame = (frames & 1) != 0;
			last = now;
			
			VRCGraphics.Blit( null, computeBuffer, computeMaterial, -1 ); 
			VRCGraphics.Blit( null, systemMemory, systemWriter, -1 ); 

			terminalInternal.SetTexture( "_ReadFromTerminal", bIsOddFrame?terminalInternal1:terminalInternal2 );
			VRCGraphics.Blit( null, bIsOddFrame?terminalInternal2:terminalInternal1, terminalInternal, -1 ); 
			terminalShow.SetTexture( "_ReadFromTerminal", bIsOddFrame?terminalInternal2:terminalInternal1 );
			
			statistics.SetTexture( "_LastStat", bIsOddFrame ? statisticsBack : statisticsTexture );
			VRCGraphics.Blit( null, bIsOddFrame ? statisticsTexture : statisticsBack, statistics, -1 ); 
			if( i == 0 ) statistics.SetFloat( "_Advance", 0.0f );
			frames++;
		}
		
		if( step )
		{
			computeMaterial.SetFloat( "_SingleStep", 0.0f );
			step = false;
			running = false;
		}
	}

	public void Restart()
	{
		frames = 0;
		
		bool bIsOddFrame = (frames & 1) != 0;

		VRCGraphics.Blit( null, systemMemory, loadImage, -1 ); 

		statistics.SetFloat( "_Reset", 1 );
		statistics.SetTexture( "_LastStat", null );
		VRCGraphics.Blit( null, statisticsTexture, statistics, -1 ); 
		VRCGraphics.Blit( null, statisticsBack, statistics, -1 ); 
		statistics.SetFloat( "_Reset", 0 );

		last = System.DateTime.Now;
		Debug.Log( "Loading System Memory: " + frames );
	}
	
	public void Redownload()
	{
		if( !doneInitial )
		{
			// It's important to store the VRCImageDownloader as a variable, to stop it from being garbage collected!
			_imageDownloader = new VRCImageDownloader();
			// To receive Image and String loading events, 'this' is casted to the type needed
			_udonEventReceiver = (IUdonEventReceiver)this;
			
			doneInitial = true;
		}
		
		var rgbInfo = new TextureInfo();
		rgbInfo.GenerateMipMaps = false;
		_imageDownloader.DownloadImage( stringUrl, loadImage, _udonEventReceiver, rgbInfo);
		Debug.Log($"Trying download.");
	}
	
	public override void OnImageLoadSuccess(IVRCImageDownload result)
	{
		Debug.Log($"Image loaded: {result.SizeInMemoryBytes} bytes.");
		//Renderer renderer = crt.GetComponent<Renderer>();
		loadImage.SetTexture( "_ImportTexture", result.Result );
		Restart();
	}

	public void ToggleRun()
	{
		running = !running;
	}

	public void Step()
	{
		running = true;
		step = true;
	}
}
