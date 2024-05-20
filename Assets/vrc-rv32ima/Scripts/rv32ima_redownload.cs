
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class rv32ima_redownload : UdonSharpBehaviour
{
	public rv32ima rv;
    void Start()
    {
        
    }
	
	public override void Interact()
	{
		rv.Redownload();
	}
}
