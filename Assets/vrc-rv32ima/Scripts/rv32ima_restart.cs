
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class rv32ima_restart : UdonSharpBehaviour
{
	public rv32ima rv;
    void Start()
    {
        
    }
	
	public override void Interact()
	{
		rv.Restart();
	}
}
