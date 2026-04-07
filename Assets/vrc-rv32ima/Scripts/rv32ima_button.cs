
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class rv32ima_button : UdonSharpBehaviour
{
	public string ButtonOperation;
	public Texture loadTexture;

	public rv32ima rv;
	void Start()
	{
		
	}
	public override void Interact()
	{
		switch( ButtonOperation )
		{
		case "Load":
			rv.loadImage.SetTexture( "_ImportTexture", loadTexture );
			break;
		case "Redownload":
			rv.Redownload();
			break;
		case "Restart":
			rv.Restart();
			break;
		case "Step":
			rv.Step();
			break;
		case "ToggleRun":
			rv.ToggleRun();
			break;
		}
	}
}
