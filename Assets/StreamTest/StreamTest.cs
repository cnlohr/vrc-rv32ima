
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

using VRC.SDK3.Components.Video;
using VRC.SDK3.Video.Components;
using VRC.SDK3.Video.Components.AVPro;
using VRC.SDK3.Video.Components.Base;


public class StreamTest : UdonSharpBehaviour
{
	public VRCAVProVideoPlayer p;
	
    void Start()
    {
        
    }
	
	public override void Interact()
	{
		p.Loop = false;
        p.EnableAutomaticResync = false;
        p.Stop();
		p.Play();
	}
}

