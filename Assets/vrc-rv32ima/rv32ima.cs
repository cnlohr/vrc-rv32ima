﻿
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

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

	private int frames;
	public int iterations = 100;
	private System.DateTime last;
	private double lastTime = 0;
	public double timeCompression = 0.1;
	private double statAdvance = 0;
	private bool running = true;
	private bool step = false;

	void Start()
	{
		computeMaterial.SetVector( "_SystemMemorySize", new Vector4( systemMemory.width, systemMemory.height, 0, 0 ) );
		loadImage.SetVector( "_SystemMemorySize", new Vector4( systemMemory.width, systemMemory.height, 0, 0 ) );
		systemWriter.SetVector( "_SystemMemorySize", new Vector4( systemMemory.width, systemMemory.height, 0, 0 ) );

		terminalInternal.SetTexture( "_SystemMemory", systemMemory );
        statisticsBack = new RenderTexture(statisticsTexture.width, statisticsTexture.height, 1, RenderTextureFormat.ARGBInt );
        statisticsBack.Create();
		last = System.DateTime.Now;
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
