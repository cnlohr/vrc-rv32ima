
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

	public Material      loadImage;
	
	public Texture       mainTexture;

	void Start()
	{
		VRCGraphics.Blit( null, systemMemory, loadImage, -1 ); 
	}

	void Update()
	{
	//	VRCGraphics.Blit( null, computeBuffer, computeMaterial, -1 ); 
	//	VRCGraphics.Blit( null, systemMemory, systemWriter, -1 ); 
	}

	public override void Interact()
	{
		Debug.Log( "Loading System Memory\n" );
		VRCGraphics.Blit( mainTexture, systemMemory, loadImage, -1 ); 
	}
}
