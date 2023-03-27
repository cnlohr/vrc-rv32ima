
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
		computeMaterial.SetVector( "_SystemMemorySize", new Vector4( systemMemory.width, systemMemory.height, 0, 0 ) );
		loadImage.SetVector( "_SystemMemorySize", new Vector4( systemMemory.width, systemMemory.height, 0, 0 ) );
		systemWriter.SetVector( "_SystemMemorySize", new Vector4( systemMemory.width, systemMemory.height, 0, 0 ) );

		VRCGraphics.Blit( mainTexture, systemMemory, loadImage, -1 ); 
	}

	void Update()
	{
		VRCGraphics.Blit( null, computeBuffer, computeMaterial, -1 ); 
		VRCGraphics.Blit( null, systemMemory, systemWriter, -1 ); 
	}

	public override void Interact()
	{
		VRCGraphics.Blit( mainTexture, systemMemory, loadImage, -1 ); 
		Debug.Log( "Loading System Memory\n" );
	}
}
